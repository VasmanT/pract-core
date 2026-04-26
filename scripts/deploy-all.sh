#!/bin/bash
set -e

# Параметры
PROFILE="${1:-prod}"  # profile: dev или prod
#PROFILE="${1:-dev}"  # profile: dev или prod

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Конфигурация сервисов
declare -A SERVICES=(
    ["practice"]="practice:practice-1.0-SNAPSHOT.jar:8095"
    ["dbmicro"]="dbmicro:dbmicro-1.0-SNAPSHOT.jar:8096"
)

# Конфигурация контейнеров (имена фиксированные)
declare -A CONTAINERS=(
    ["practice"]="myapp-practice"
    ["dbmicro"]="myapp-dbmicro"
)

# Функция проверки зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен"
        exit 1
    fi

    if ! command -v mvn &> /dev/null; then
        print_error "Maven не установлен"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker демон не запущен"
        exit 1
    fi

    print_success "Все зависимости установлены"
}

# Функция проверки существования контейнера
check_container() {
    local service_name=$1
    local container_name=${CONTAINERS[$service_name]}

    if ! docker inspect "$container_name" &> /dev/null; then
        print_error "Контейнер $container_name не существует!"
        print_error "Сначала запустите: ./scripts/create-containers.sh"
        exit 1
    fi

    print_success "Контейнер $container_name найден"
}

# Функция сборки модуля
build_module() {
    local module_name=$1
    local module_path="$PROJECT_ROOT/$module_name"

    print_info "Сборка модуля $module_name..."
    cd "$module_path"

    if mvn clean package -DskipTests; then
        print_success "Модуль $module_name собран успешно"
    else
        print_error "Ошибка при сборке модуля $module_name"
        exit 1
    fi
}

# Функция деплоя сервиса
deploy_service() {
    local service_name=$1
    local container_name=${CONTAINERS[$service_name]}
    local module_name=$(echo ${SERVICES[$service_name]} | cut -d':' -f1)
    local jar_name=$(echo ${SERVICES[$service_name]} | cut -d':' -f2)
    local port=$(echo ${SERVICES[$service_name]} | cut -d':' -f3)

    local jar_path="$PROJECT_ROOT/$module_name/target/$jar_name"

    print_info "========================================="
    print_info "Деплой сервиса: $service_name"
    print_info "Контейнер: $container_name"
    print_info "JAR: $jar_path"
    print_info "Порт: $port"

    # Проверка JAR файла
    if [ ! -f "$jar_path" ]; then
        print_error "JAR файл не найден: $jar_path"
        # Ищем альтернативные пути
        find "$PROJECT_ROOT/$module_name/target" -name "*.jar" 2>/dev/null || true
        exit 1
    fi
    print_success "JAR файл найден: $(ls -lh "$jar_path")"

    # Копирование JAR в контейнер
    print_info "Копирование JAR в контейнер..."
    if docker cp "$jar_path" "${container_name}:/app/app.jar"; then
        print_success "JAR файл скопирован"
    else
        print_error "Ошибка при копировании JAR"
        exit 1
    fi

    # Перезапуск приложения внутри контейнера
    print_info "Перезапуск приложения с профилем '$PROFILE'..."

    # Убиваем старый процесс Java и запускаем новый
    docker exec "$container_name" sh -c "
        pkill -f 'java.*jar' 2>/dev/null || true
        sleep 2
        export SPRING_PROFILES_ACTIVE=$PROFILE
        nohup java -jar /app/app.jar \
            --spring.profiles.active=$PROFILE \
            --server.port=$port > /app/app.log 2>&1 &
        echo 'Приложение запущено'
    "

    sleep 3

    # Проверка запуска
    print_info "Проверка статуса..."
    if docker exec "$container_name" pgrep -f "java.*jar" &> /dev/null; then
        print_success "Процесс Java запущен"
    else
        print_warning "Процесс Java не найден, проверьте логи"
        docker exec "$container_name" cat /app/app.log 2>/dev/null || true
    fi

    print_success "Сервис $service_name обновлен"
}

# Функция проверки работоспособности
check_health() {
    local service_name=$1
    local port=$(echo ${SERVICES[$service_name]} | cut -d':' -f3)
    local max_attempts=30
    local interval=2

    print_info "Проверка работоспособности $service_name на порту $port..."

    for ((i=1; i<=max_attempts; i++)); do
        if curl -s -f --max-time 2 "http://localhost:$port/actuator/health" &> /dev/null; then
            print_success "$service_name отвечает на /actuator/health"
            return 0
        elif curl -s -f --max-time 2 "http://localhost:$port" &> /dev/null; then
            print_success "$service_name отвечает на корневой URL"
            return 0
        fi

        printf "."
        sleep $interval
    done

    echo ""
    print_warning "$service_name не отвечает на запросы"
    return 1
}

# Основная функция
main() {
    echo "========================================="
    print_info "=== МАССОВЫЙ ДЕПЛОЙ ВСЕХ СЕРВИСОВ ==="
    print_info "Профиль: $PROFILE"
    echo "========================================="

    # Проверка зависимостей
    check_dependencies

    # Проверка существования всех контейнеров
    for service in "${!SERVICES[@]}"; do
        check_container "$service"
    done

    # Сборка всех модулей
    print_info "=== СБОРКА МОДУЛЕЙ ==="
    for service in "${!SERVICES[@]}"; do
        module_name=$(echo ${SERVICES[$service]} | cut -d':' -f1)
        build_module "$module_name"
    done

    # Деплой всех сервисов
    print_info "=== ДЕПЛОЙ СЕРВИСОВ ==="
    for service in "${!SERVICES[@]}"; do
        deploy_service "$service"
    done

    # Проверка работоспособности
    print_info "=== ПРОВЕРКА РАБОТОСПОСОБНОСТИ ==="
    sleep 5

    local all_healthy=true
    for service in "${!SERVICES[@]}"; do
        if ! check_health "$service"; then
            all_healthy=false
        fi
    done

    echo "========================================="
    if [ "$all_healthy" = true ]; then
        print_success "=== ВСЕ СЕРВИСЫ УСПЕШНО ЗАПУЩЕНЫ! ==="
    else
        print_warning "=== НЕКОТОРЫЕ СЕРВИСЫ МОГУТ НЕ РАБОТАТЬ ==="
    fi

    # Итоговая информация
    echo "========================================="
    print_info "=== ИНФОРМАЦИЯ О КОНТЕЙНЕРАХ ==="
    docker ps --filter "name=myapp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo "========================================="
    print_info "Команды для управления:"
    print_info "  Логи всех сервисов:  docker logs -f myapp-practice & docker logs -f myapp-dbmicro"
    print_info "  Логи конкретного:     docker logs -f myapp-practice"
    print_info "  Остановка всех:       docker stop myapp-practice myapp-dbmicro"
    print_info "  Запуск всех:          docker start myapp-practice myapp-dbmicro"
    print_info "  Перезапуск всех:      docker restart myapp-practice myapp-dbmicro"
    echo "========================================="
}

# Обработка ошибок
trap 'print_error "Скрипт прерван пользователем (Ctrl+C)"; exit 1' INT

# Запуск
main "$@"