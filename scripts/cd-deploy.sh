#!/bin/bash
# cd-deploy.sh - Только CD: развертывание готовых образов

set -e

# Параметры
ENVIRONMENT="${1:-prod}"  # dev, staging, prod
TAG="${2:-latest}"        # Тег образа для деплоя
ACTION="${3:-deploy}"     # deploy, rollback, status, logs

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CD]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Конфигурация окружений
case "$ENVIRONMENT" in
    dev)
        REGISTRY="dev-registry.example.com/"
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env.dev"
        ;;
    staging)
        REGISTRY="staging-registry.example.com/"
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env.staging"
        ;;
    prod)
        REGISTRY="prod-registry.example.com/"
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env.prod"
        ;;
    *)
        print_error "Неизвестное окружение: $ENVIRONMENT"
        exit 1
        ;;
esac

export TAG
export REGISTRY

# Загрузка переменных окружения
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    print_info "Загружен конфиг: $ENV_FILE"
fi

# Функция проверки доступности образов
check_images() {
    print_info "Проверка наличия образов..."

    local services=("practice" "dbmicro")
    local missing=()

    for service in "${services[@]}"; do
        local image="${REGISTRY}${service}:${TAG}"

        # Проверяем локально
        if ! docker image inspect "$image" &>/dev/null; then
            print_warning "Образ $image не найден локально"

            # Пытаемся скачать
            print_info "Скачиваем $image..."
            if docker pull "$image"; then
                print_success "Образ $image скачан"
            else
                missing+=("$image")
            fi
        else
            print_success "Образ $image найден локально"
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Не удалось получить образы: ${missing[*]}"
        exit 1
    fi
}

# Функция бэкапа текущей версии
backup_current() {
    local backup_dir="./backups/${ENVIRONMENT}"
    mkdir -p "$backup_dir"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local current_tag=$(docker inspect myapp-practice --format='{{.Config.Image}}' 2>/dev/null | cut -d':' -f2 || echo "none")

    echo "$current_tag" > "$backup_dir/prev_version_${timestamp}.txt"
    print_info "Текущая версия: $current_tag (сохранена)"
}

# Функция деплоя
deploy() {
    print_info "Начинаем деплой в окружение: $ENVIRONMENT"
    print_info "Версия образа: $TAG"

    # Проверяем образы
    check_images

    # Сохраняем текущую версию для rollback
    backup_current

    # Останавливаем текущие сервисы
    print_info "Останавливаем текущие сервисы..."
    docker compose -f "$COMPOSE_FILE" down

    # Запускаем новые сервисы
    print_info "Запускаем новые сервисы..."
    docker compose -f "$COMPOSE_FILE" up -d

    # Ожидаем готовности
    wait_for_services

    # Проверяем здоровье
    check_health

    print_success "Деплой успешно завершен!"
}

# Функция ожидания сервисов
wait_for_services() {
    print_info "Ожидание готовности сервисов (макс. 60 сек)..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local all_ready=true

        # Проверка practice
        if ! curl -s -f http://localhost:8095/actuator/health &>/dev/null; then
            all_ready=false
        fi

        # Проверка dbmicro
        if ! curl -s -f http://localhost:8096/actuator/health &>/dev/null; then
            all_ready=false
        fi

        # Проверка БД
        if ! docker exec myapp-practicedb pg_isready -U postgres &>/dev/null; then
            all_ready=false
        fi

        if [ "$all_ready" = true ]; then
            print_success "Все сервисы готовы"
            return 0
        fi

        printf "."
        sleep 2
        ((attempt++))
    done

    echo ""
    print_warning "Не все сервисы готовы"
    show_status
}

# Функция проверки здоровья
check_health() {
    print_info "Проверка здоровья сервисов..."

    docker compose -f "$COMPOSE_FILE" ps

    # Детальная проверка
    for service in practice dbmicro; do
        local health=$(docker inspect --format='{{.State.Health.Status}}' "myapp-$service" 2>/dev/null || echo "N/A")
        if [ "$health" != "healthy" ]; then
            print_warning "Сервис $service: $health"
        else
            print_success "Сервис $service: healthy"
        fi
    done
}

# Функция rollback
rollback() {
    local prev_version_file="./backups/${ENVIRONMENT}/prev_version_*.txt"
    local prev_version=$(ls -t $prev_version_file 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "")

    if [ -z "$prev_version" ] || [ "$prev_version" = "none" ]; then
        print_error "Нет предыдущей версии для rollback"
        exit 1
    fi

    print_info "Откат к версии: $prev_version"
    export TAG="$prev_version"

    deploy
}

# Функция blue-green деплоя
blue_green_deploy() {
    print_info "Blue-Green деплой в окружение: $ENVIRONMENT"

    local new_tag="$TAG"
    local blue_port=8095
    local green_port=8097
    local active_color=""

    # Определяем активный цвет
    if curl -s -f http://localhost:8095/actuator/health &>/dev/null; then
        active_color="blue"
    elif curl -s -f http://localhost:8097/actuator/health &>/dev/null; then
        active_color="green"
    fi

    # Создаем временный compose файл для нового окружения
    local temp_compose="docker-compose.${active_color:-blue}.yml"

    if [ "$active_color" = "blue" ] || [ -z "$active_color" ]; then
        # Деплоим в green
        print_info "Деплой в green окружение (порт 8097)"
        export ALTERNATE_PORT=8097
        envsubst < docker-compose.template.yml > "$temp_compose"

        # Запускаем новую версию
        docker compose -f "$temp_compose" up -d

        # Ждем готовности
        sleep 20

        # Переключаем трафик
        print_info "Переключаем трафик на green"
        # Здесь логика обновления reverse proxy или балансировщика

        # Останавливаем blue
        docker compose -f docker-compose.yml stop practice dbmicro
    else
        # Аналогично для blue
        print_info "Деплой в blue окружение (порт 8095)"
        # ...
    fi
}

# Функция отображения статуса
show_status() {
    print_info "Статус сервисов:"
    docker compose -f "$COMPOSE_FILE" ps

    echo ""
    print_info "Версии образов:"
    docker inspect myapp-practice --format='practice: {{.Config.Image}}' 2>/dev/null || echo "practice: не запущен"
    docker inspect myapp-dbmicro --format='dbmicro: {{.Config.Image}}' 2>/dev/null || echo "dbmicro: не запущен"
}

# Функция показа логов
show_logs() {
    local service="$1"
    if [ -n "$service" ]; then
        docker compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        docker compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Функция остановки
stop() {
    print_info "Остановка сервисов в окружении: $ENVIRONMENT"
    docker compose -f "$COMPOSE_FILE" down
    print_success "Сервисы остановлены"
}

# Функция очистки старых образов на сервере
cleanup_old() {
    print_info "Очистка старых образов на сервере..."

    # Удаляем образы старше 30 дней
    docker image prune -a --filter "until=720h" -f

    # Удаляем неиспользуемые тома
    docker volume prune -f

    print_success "Очистка завершена"
}

# Функция сравнения версий
compare_versions() {
    local current=$(docker inspect myapp-practice --format='{{.Config.Image}}' 2>/dev/null | cut -d':' -f2 || echo "none")
    local target="$TAG"

    if [ "$current" = "$target" ]; then
        print_warning "Текущая версия ($current) совпадает с целевой ($target)"
        read -p "Продолжить деплой? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        print_info "Обновление: $current → $target"
    fi
}

# Помощь
show_help() {
    cat << EOF
${CYAN}CD Deployment Script${NC}

${CYAN}Использование:${NC}
  ./cd-deploy.sh <ENVIRONMENT> <TAG> <ACTION>

${CYAN}Параметры:${NC}
  ENVIRONMENT   dev, staging, prod
  TAG           Тег образа (commit hash, version, latest)
  ACTION        Действие (deploy, rollback, blue-green, status, logs, stop, clean)

${CYAN}Примеры:${NC}
  ./cd-deploy.sh prod v1.2.3 deploy      # Деплой версии v1.2.3 в production
  ./cd-deploy.sh prod latest deploy      # Деплой последней версии
  ./cd-deploy.sh staging abc1234 deploy  # Деплой конкретного коммита в staging
  ./cd-deploy.sh prod v1.2.3 rollback    # Откат к предыдущей версии
  ./cd-deploy.sh prod v1.2.3 blue-green  # Blue-green деплой
  ./cd-deploy.sh prod latest status      # Статус сервисов
  ./cd-deploy.sh prod latest stop        # Остановить все сервисы
  ./cd-deploy.sh prod latest clean       # Очистить старые образы

${CYAN}Файлы окружений:${NC}
  .env.dev       - переменные для dev
  .env.staging   - переменные для staging
  .env.prod      - переменные для prod

EOF
}

# Главная функция
main() {
    echo "========================================="
    print_info "CD PIPELINE STARTED"
    print_info "Environment: ${ENVIRONMENT}"
    print_info "Tag: ${TAG}"
    print_info "Action: ${ACTION}"
    echo "========================================="

    case "$ACTION" in
        deploy)
            compare_versions
            deploy
            ;;
        rollback)
            rollback
            ;;
        blue-green)
            blue_green_deploy
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$4"
            ;;
        stop)
            stop
            ;;
        clean)
            cleanup_old
            ;;
        *)
            show_help
            exit 1
            ;;
    esac

    echo "========================================="
    print_success "CD PIPELINE FINISHED"
    echo "========================================="
}

main "$@"