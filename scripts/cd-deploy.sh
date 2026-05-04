#!/bin/bash
# cd-deploy.sh - Только деплой готовых образов

set -e

ENVIRONMENT="${1:-prod}"
TAG="${2:-latest}"
ACTION="${3:-deploy}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CD]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Определяем корневую директорию проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

export TAG
export REGISTRY="${REGISTRY:-}"

print_info "Проект в: $PROJECT_ROOT"
print_info "Окружение: $ENVIRONMENT, версия: $TAG"

# Загружаем переменные для конкретного окружения (без source)
load_env() {
    local env_file="$PROJECT_ROOT/.env.${ENVIRONMENT}"

    if [ -f "$env_file" ]; then
        print_info "Загрузка конфигурации из $env_file"

        # Читаем файл построчно и экспортируем переменные
        while IFS='=' read -r key value; do
            # Пропускаем комментарии и пустые строки
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue

            # Убираем пробелы и кавычки
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//')

            # Экспортируем переменную
            export "$key"="$value"
        done < "$env_file"

        print_success "Переменные загружены"
    else
        print_warning "Файл $env_file не найден, используются значения по умолчанию"
        export PROFILE="$ENVIRONMENT"
        export TZ="Europe/Moscow"
        export JAVA_OPTS="-Xmx512m -Xms256m"
    fi

    # Выводим загруженные переменные (без значений для безопасности)
    print_info "Загружены: PROFILE, TZ, JAVA_OPTS"
}

# Проверка и скачивание образов
pull_images() {
    print_info "Проверка образов..."

    for img in practice dbmicro; do
        local image="${REGISTRY}${img}:${TAG}"
        if ! docker image inspect "$image" &>/dev/null; then
            print_info "Скачивание $image"
            docker pull "$image" 2>/dev/null || print_warning "Не удалось скачать $image, возможно образ локальный"
        else
            print_success "Образ $image найден локально"
        fi
    done
}

# Деплой
deploy() {
    print_info "Деплой в $ENVIRONMENT, версия: $TAG"

    load_env
    pull_images

    # Показываем используемые переменные
    echo ""
    print_info "Переменные окружения для контейнеров:"
    echo "  PROFILE=${PROFILE}"
    echo "  TZ=${TZ}"
    echo "  JAVA_OPTS=${JAVA_OPTS}"
    echo ""

    # Остановка старых контейнеров
    print_info "Остановка старых контейнеров..."
    docker compose down 2>/dev/null || true

    # Запуск новых
    print_info "Запуск новых контейнеров..."
    docker compose up -d

    # Ожидание готовности
    print_info "Ожидание готовности сервисов..."
    sleep 15

    # Проверка healthcheck
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local practice_ok=false
        local dbmicro_ok=false

        if curl -s -f http://localhost:8095/actuator/health &>/dev/null 2>&1; then
            practice_ok=true
        fi

        if curl -s -f http://localhost:8096/actuator/health &>/dev/null 2>&1; then
            dbmicro_ok=true
        fi

        if [ "$practice_ok" = true ] && [ "$dbmicro_ok" = true ]; then
            print_success "Все сервисы готовы"
            break
        fi

        printf "."
        sleep 2
        ((attempt++))
    done

    echo ""

    # Финальная проверка
    if curl -s -f http://localhost:8095/actuator/health &>/dev/null 2>&1; then
        print_success "Practice OK"
    else
        print_warning "Practice healthcheck не прошел"
        echo "Логи practice:"
        docker logs myapp-practice --tail 20 2>/dev/null || true
    fi

    if curl -s -f http://localhost:8096/actuator/health &>/dev/null 2>&1; then
        print_success "DBMicro OK"
    else
        print_warning "DBMicro healthcheck не прошел"
        echo "Логи dbmicro:"
        docker logs myapp-dbmicro --tail 20 2>/dev/null || true
    fi

    print_success "Деплой завершен"
    echo ""
    print_info "Проверка статуса: docker compose ps"
    docker compose ps
}

# Откат
rollback() {
    print_info "Откат к версии: $TAG"
    deploy
}

# Статус
status() {
    load_env
    docker compose ps
    echo ""
    echo "Версии образов:"
    docker inspect myapp-practice --format='practice: {{.Config.Image}}' 2>/dev/null || echo "practice: не запущен"
    docker inspect myapp-dbmicro --format='dbmicro: {{.Config.Image}}' 2>/dev/null || echo "dbmicro: не запущен"
}

# Остановка
stop() {
    print_info "Остановка всех сервисов"
    docker compose down
    print_success "Сервисы остановлены"
}

# Логи
logs() {
    local service="$1"
    if [ -n "$service" ]; then
        docker compose logs -f "$service"
    else
        docker compose logs -f
    fi
}

case "$ACTION" in
    deploy) deploy ;;
    rollback) rollback ;;
    status) status ;;
    stop) stop ;;
    logs) logs "$4" ;;
    *)
        echo "Использование: $0 <env> <tag> {deploy|rollback|status|stop|logs}"
        echo ""
        echo "Примеры:"
        echo "  $0 dev latest deploy"
        echo "  $0 prod v1.0.0 deploy"
        echo "  $0 prod latest status"
        echo "  $0 dev latest stop"
        echo "  $0 prod latest logs practice"
        ;;
esac