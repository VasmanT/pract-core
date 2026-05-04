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
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

export TAG
export REGISTRY="${REGISTRY:-}"

# Загружаем переменные для конкретного окружения
load_env() {
    local env_file=".env.${ENVIRONMENT}"

    if [ -f "$env_file" ]; then
        print_info "Загрузка конфигурации из $env_file"
        set -a
        source "$env_file"
        set +a
    else
        print_warning "Файл $env_file не найден, используются значения по умолчанию"
    fi
}

# Проверка и скачивание образов
pull_images() {
    print_info "Проверка образов..."

    for img in practice dbmicro; do
        local image="${REGISTRY}${img}:${TAG}"
        if ! docker image inspect "$image" &>/dev/null; then
            print_info "Скачивание $image"
            docker pull "$image"
        fi
    done
}

# Деплой
deploy() {
    print_info "Деплой в $ENVIRONMENT, версия: $TAG"

    load_env
    pull_images
    docker compose down
    docker compose up -d

    # Ожидание готовности
    sleep 15
    if curl -s -f http://localhost:8095/actuator/health &>/dev/null; then
        print_success "Practice OK"
    else
        print_error "Practice healthcheck failed"
    fi

    if curl -s -f http://localhost:8096/actuator/health &>/dev/null; then
        print_success "DBMicro OK"
    else
        print_error "DBMicro healthcheck failed"
    fi

    print_success "Деплой завершен"
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
    docker inspect myapp-practice --format='practice: {{.Config.Image}}' 2>/dev/null || echo "practice: not running"
    docker inspect myapp-dbmicro --format='dbmicro: {{.Config.Image}}' 2>/dev/null || echo "dbmicro: not running"
}

case "$ACTION" in
    deploy) deploy ;;
    rollback) rollback ;;
    status) status ;;
    *) echo "Использование: $0 <env> <tag> {deploy|rollback|status}" ;;
esac