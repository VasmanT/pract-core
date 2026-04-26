#!/bin/bash
# deploy-with-compose.sh

set -e

# Параметры по умолчанию
PROFILE="${1:-prod}"
ACTION="${2:-up}"  # up, down, restart, rebuild, logs, status

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "\n${BLUE}▶ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Экспортируем переменные для docker-compose
export PROFILE
export TZ="${TZ:-Europe/Moscow}"
export JAVA_OPTS="${JAVA_OPTS:--Xmx512m -Xms256m}"

# Создаем временный .env файл для docker-compose
create_env_file() {
    local env_file="$PROJECT_ROOT/.env"
    cat > "$env_file" << EOF
PROFILE=$PROFILE
TZ=$TZ
JAVA_OPTS=$JAVA_OPTS
EOF
    echo "$env_file"
}

# Функция проверки зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен"
        exit 1
    fi

    # Проверяем docker compose (новая версия) или docker-compose (старая)
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
        print_success "Docker Compose (plugin) найден"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
        print_success "Docker Compose (standalone) найден"
    else
        print_error "Docker Compose не установлен"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker демон не запущен"
        exit 1
    fi

    print_success "Все зависимости установлены"
}

# Функция сборки JAR файлов
build_jar() {
    local module=$1
    local module_path="$PROJECT_ROOT/$module"

    print_info "Сборка модуля $module..."

    if [ ! -d "$module_path" ]; then
        print_error "Директория модуля не найдена: $module_path"
        return 1
    fi

    cd "$module_path"
    if mvn clean package -DskipTests; then
        print_success "Модуль $module собран успешно"
    else
        print_error "Ошибка при сборке модуля $module"
        cd "$PROJECT_ROOT"
        exit 1
    fi
    cd "$PROJECT_ROOT"
}

# Функция сборки Docker образов
build_images() {
    print_step "Сборка Docker образов"

    # Сборка JAR файлов
    build_jar "practice"
    build_jar "dbmicro"

    # Создаем .env файл
    local env_file=$(create_env_file)
    print_info "Создан .env файл: $env_file"

    # Сборка Docker образов через compose
    print_info "Сборка Docker образов с профилем: $PROFILE"
    $DOCKER_COMPOSE build

    print_success "Образы собраны успешно"
}

# Функция запуска сервисов
start_services() {
    print_step "Запуск сервисов"

    # Создаем .env файл
    create_env_file > /dev/null

    # Запускаем все сервисы
    $DOCKER_COMPOSE up -d

    print_success "Сервисы запущены"

    # Ожидание готовности
    wait_for_services
}

# Функция ожидания готовности сервисов
wait_for_services() {
    print_step "Ожидание готовности сервисов"

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local practice_ready=false
        local dbmicro_ready=false

        # Проверка practice
        if curl -s -f http://localhost:8095/actuator/health &> /dev/null 2>&1; then
            practice_ready=true
        fi

        # Проверка dbmicro
        if curl -s -f http://localhost:8096/actuator/health &> /dev/null 2>&1; then
            dbmicro_ready=true
        fi

        # Проверка БД
        local db_ready=false
        if docker exec myapp-practicedb pg_isready -U postgres &> /dev/null; then
            db_ready=true
        fi

        if [ "$practice_ready" = true ] && [ "$dbmicro_ready" = true ] && [ "$db_ready" = true ]; then
            print_success "Все сервисы готовы к работе"
            return 0
        fi

        printf "."
        sleep 2
        ((attempt++))
    done

    echo ""
    print_warning "Не все сервисы ответили на healthcheck"

    # Показываем статус контейнеров
    $DOCKER_COMPOSE ps
}

# Функция перезапуска конкретного сервиса
restart_service() {
    local service=$1

    if [ -z "$service" ]; then
        print_step "Перезапуск всех сервисов"
        $DOCKER_COMPOSE restart
    else
        print_step "Перезапуск сервиса: $service"
        $DOCKER_COMPOSE restart "$service"
    fi

    wait_for_services
}

# Функция обновления конкретного сервиса (пересборка + перезапуск)
update_service() {
    local service=$1

    if [ -z "$service" ]; then
        print_error "Укажите сервис для обновления: practice или dbmicro"
        exit 1
    fi

    print_step "Обновление сервиса: $service"

    # Определяем модуль для сборки
    local module=""
    case "$service" in
        practice)
            module="practice"
            ;;
        dbmicro)
            module="dbmicro"
            ;;
        *)
            print_error "Неизвестный сервис: $service"
            exit 1
            ;;
    esac

    # Сборка JAR
    build_jar "$module"

    # Пересборка образа конкретного сервиса
    $DOCKER_COMPOSE build "$service"

    # Перезапуск с пересозданием
    $DOCKER_COMPOSE up -d --no-deps --force-recreate "$service"

    wait_for_services

    print_success "Сервис $service обновлен"
}

# Функция остановки сервисов
stop_services() {
    print_step "Остановка сервисов"

    if [ "$1" = "--clean" ]; then
        print_info "Остановка с удалением контейнеров и томов"
        $DOCKER_COMPOSE down -v
        # Удаляем .env файл
        rm -f "$PROJECT_ROOT/.env"
        print_success "Все контейнеры и тома удалены"
    else
        $DOCKER_COMPOSE down
        print_success "Сервисы остановлены (данные сохранены)"
    fi
}

# Функция показа статуса
show_status() {
    print_step "Статус сервисов"
    $DOCKER_COMPOSE ps

    echo ""
    print_step "Healthcheck статус"

    # Проверка healthcheck
    for service in practice dbmicro; do
        local health=$(docker inspect --format='{{.State.Health.Status}}' "myapp-$service" 2>/dev/null || echo "N/A")
        printf "%-10s: %s\n" "$service" "$health"
    done

    echo ""
    print_step "Проверка доступности"

    # Проверка через curl
    if curl -s -f http://localhost:8095/actuator/health &> /dev/null; then
        print_success "Practice: http://localhost:8095 - OK"
    else
        print_warning "Practice: http://localhost:8095 - недоступен"
    fi

    if curl -s -f http://localhost:8096/actuator/health &> /dev/null; then
        print_success "DBMicro: http://localhost:8096 - OK"
    else
        print_warning "DBMicro: http://localhost:8096 - недоступен"
    fi
}

# Функция показа логов
show_logs() {
    local service=$1

    if [ -z "$service" ]; then
        print_step "Логи всех сервисов"
        $DOCKER_COMPOSE logs -f
    else
        print_step "Логи сервиса: $service"
        $DOCKER_COMPOSE logs -f "$service"
    fi
}

# Функция выполнения команд внутри контейнера
exec_command() {
    local service=$1
    shift
    local cmd="$@"

    if [ -z "$service" ] || [ -z "$cmd" ]; then
        print_error "Использование: $0 exec <service> <command>"
        print_error "Пример: $0 exec practice ls -la /app"
        exit 1
    fi

    $DOCKER_COMPOSE exec "$service" $cmd
}

# Функция очистки
clean_all() {
    print_step "Полная очистка"

    print_info "Остановка и удаление контейнеров..."
    $DOCKER_COMPOSE down -v

    print_info "Удаление образов..."
    docker rmi myapp-practice myapp-dbmicro 2>/dev/null || true

    print_info "Удаление .env файла..."
    rm -f "$PROJECT_ROOT/.env"

    print_success "Полная очистка выполнена"
}

# Показать помощь
show_help() {
    cat << EOF
${CYAN}Использование:${NC} $0 [PROFILE] [ACTION] [OPTIONS]

${CYAN}Параметры:${NC}
  PROFILE         dev или prod (по умолчанию: prod)
  ACTION          Действие (по умолчанию: up)

${CYAN}Действия:${NC}
  up              Запустить все сервисы (сборка + запуск)
  down            Остановить все сервисы
  down --clean    Остановить и удалить все контейнеры и тома
  restart         Перезапустить все сервисы
  restart <service> Перезапустить конкретный сервис
  update <service> Обновить конкретный сервис (пересборка + перезапуск)
  rebuild         Полная пересборка и запуск
  status          Показать статус сервисов
  logs            Показать логи всех сервисов
  logs <service>  Показать логи конкретного сервиса
  exec <service> <cmd> Выполнить команду в контейнере
  clean           Полная очистка (контейнеры, тома, образы, .env)

${CYAN}Примеры:${NC}
  $0 dev up                    # Запуск с профилем dev
  $0 prod up                   # Запуск с профилем prod
  $0 prod restart practice     # Перезапустить только practice
  $0 prod update practice      # Обновить practice (пересобрать и перезапустить)
  $0 prod status               # Проверить статус
  $0 prod logs practice        # Посмотреть логи practice
  $0 prod exec practice bash   # Зайти в контейнер practice

EOF
}

# Главная функция
main() {
    echo "========================================="
    print_info "=== УПРАВЛЕНИЕ MICROSERVICES ==="
    print_info "Профиль: $PROFILE"
    print_info "Действие: $ACTION"
    echo "========================================="

    check_dependencies

    case "$ACTION" in
        up)
            build_images
            start_services
            show_status
            ;;
        down)
            stop_services "$3"
            ;;
        restart)
            if [ -n "$3" ]; then
                restart_service "$3"
            else
                restart_service
            fi
            show_status
            ;;
        update)
            if [ -z "$3" ]; then
                print_error "Укажите сервис для обновления: practice или dbmicro"
                exit 1
            fi
            update_service "$3"
            show_status
            ;;
        rebuild)
            stop_services --clean
            build_images
            start_services
            show_status
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$3"
            ;;
        exec)
            if [ -z "$3" ] || [ -z "$4" ]; then
                print_error "Использование: $0 $PROFILE exec <service> <command>"
                exit 1
            fi
            shift 2
            exec_command "$@"
            ;;
        clean)
            clean_all
            ;;
        *)
            show_help
            ;;
    esac

    echo "========================================="
    print_success "Готово!"
}

# Обработка сигналов
trap 'print_error "Скрипт прерван"; exit 1' INT

# Запуск
main "$@"