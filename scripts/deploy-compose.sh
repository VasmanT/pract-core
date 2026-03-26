#!/bin/bash
set -e

# Параметры
PROFILE="${1:-prod}"  # profile: dev или prod
ACTION="${2:-up}"     # действие: up, down, restart, logs, build

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
    ["practice"]="practice:8095"
    ["dbmicro"]="dbmicro:8096"
)

# Функция проверки зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose не установлен"
        exit 1
    fi

    if ! command -v mvn &> /dev/null; then
        print_error "Maven не установлен"
        exit 1
    fi

    print_success "Все зависимости установлены"
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

# Функция сборки всех модулей
build_all_modules() {
    print_info "=== СБОРКА ВСЕХ МОДУЛЕЙ ==="
    for service in "${!SERVICES[@]}"; do
        module_name=$(echo ${SERVICES[$service]} | cut -d':' -f1)
        build_module "$module_name"
    done
}

# Функция сборки образа для конкретного сервиса
build_service_image() {
    local service_name=$1
    local module_name=$(echo ${SERVICES[$service_name]} | cut -d':' -f1)

    print_info "Сборка Docker образа для $service_name..."
    cd "$PROJECT_ROOT"

    # Собираем конкретный сервис через docker-compose
    PROFILE=$PROFILE docker-compose build "$service_name"

    print_success "Образ для $service_name собран"
}

# Функция запуска всех сервисов
up_all_services() {
    print_info "=== ЗАПУСК ВСЕХ СЕРВИСОВ ==="
    cd "$PROJECT_ROOT"

    PROFILE=$PROFILE docker-compose up -d

    print_success "Все сервисы запущены"
}

# Функция остановки всех сервисов
down_all_services() {
    print_info "=== ОСТАНОВКА ВСЕХ СЕРВИСОВ ==="
    cd "$PROJECT_ROOT"

    docker-compose down

    print_success "Все сервисы остановлены"
}

# Функция перезапуска конкретного сервиса
restart_service() {
    local service_name=$1

    print_info "Перезапуск сервиса $service_name..."
    cd "$PROJECT_ROOT"

    PROFILE=$PROFILE docker-compose restart "$service_name"

    print_success "Сервис $service_name перезапущен"
}

# Функция обновления конкретного сервиса (сборка + перезапуск)
update_service() {
    local service_name=$1
    local module_name=$(echo ${SERVICES[$service_name]} | cut -d':' -f1)

    print_info "=== ОБНОВЛЕНИЕ СЕРВИСА $service_name ==="

    # Сборка модуля
    build_module "$module_name"

    # Сборка образа и перезапуск
    cd "$PROJECT_ROOT"
    PROFILE=$PROFILE docker-compose up -d --build --no-deps "$service_name"

    print_success "Сервис $service_name обновлен"
}

# Функция проверки работоспособности
check_health() {
    local service_name=$1
    local port=$(echo ${SERVICES[$service_name]} | cut -d':' -f2)
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

# Функция просмотра логов
show_logs() {
    local service_name=$1
    local lines=${2:-50}

    cd "$PROJECT_ROOT"
    docker-compose logs --tail="$lines" -f "$service_name"
}

# Основная функция
main() {
    echo "========================================="
    print_info "=== УПРАВЛЕНИЕ СЕРВИСАМИ ЧЕРЕЗ DOCKER COMPOSE ==="
    print_info "Профиль: $PROFILE"
    print_info "Действие: $ACTION"
    echo "========================================="

    # Проверка зависимостей
    check_dependencies

    case $ACTION in
        "up")
            # Сборка всех модулей и запуск
            build_all_modules
            up_all_services
            ;;
        "down")
            down_all_services
            exit 0
            ;;
        "restart")
            if [ -n "$2" ]; then
                restart_service "$2"
            else
                down_all_services
                build_all_modules
                up_all_services
            fi
            ;;
        "update")
            if [ -n "$2" ]; then
                update_service "$2"
            else
                print_error "Укажите сервис для обновления: practice или dbmicro"
                exit 1
            fi
            ;;
        "build")
            if [ -n "$2" ]; then
                build_module "$2"
                build_service_image "$2"
            else
                build_all_modules
                cd "$PROJECT_ROOT"
                PROFILE=$PROFILE docker-compose build
            fi
            ;;
        "logs")
            if [ -n "$2" ]; then
                show_logs "$2" "$3"
            else
                cd "$PROJECT_ROOT"
                docker-compose logs -f
            fi
            ;;
        "status")
            cd "$PROJECT_ROOT"
            docker-compose ps
            ;;
        "health")
            sleep 5
            local all_healthy=true
            for service in "${!SERVICES[@]}"; do
                if ! check_health "$service"; then
                    all_healthy=false
                fi
            done
            if [ "$all_healthy" = true ]; then
                print_success "Все сервисы работают нормально"
            else
                print_warning "Некоторые сервисы могут не работать"
            fi
            ;;
        *)
            print_error "Неизвестное действие: $ACTION"
            echo "Доступные действия: up, down, restart, update, build, logs, status, health"
            exit 1
            ;;
    esac

    echo "========================================="
    print_info "=== ТЕКУЩЕЕ СОСТОЯНИЕ ==="
    cd "$PROJECT_ROOT"
    docker-compose ps
    echo "========================================="
}

# Обработка ошибок
trap 'print_error "Скрипт прерван пользователем (Ctrl+C)"; exit 1' INT

# Запуск
main "$@"