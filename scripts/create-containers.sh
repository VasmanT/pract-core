#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Конфигурация контейнеров
declare -A CONTAINERS=(
    ["practice"]="8095:8095"
    ["dbmicro"]="8096:8096"
)

print_info "=== СОЗДАНИЕ КОНТЕЙНЕРОВ ==="
print_info "Корневая директория: $PROJECT_ROOT"

# Создаем Docker network если не существует
NETWORK_NAME="my-app-network"
if ! docker network inspect "$NETWORK_NAME" &>/dev/null; then
    print_info "Создаем сеть $NETWORK_NAME..."
    docker network create "$NETWORK_NAME"
    print_success "Сеть создана"
fi

# Создаем контейнеры
for SERVICE_NAME in "${!CONTAINERS[@]}"; do
    PORT_MAPPING="${CONTAINERS[$SERVICE_NAME]}"
    CONTAINER_NAME="myapp-$SERVICE_NAME"

    print_info "========================================="
    print_info "Сервис: $SERVICE_NAME"
    print_info "Контейнер: $CONTAINER_NAME"
    print_info "Порты: $PORT_MAPPING"

    # Проверяем, существует ли контейнер
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        print_info "Контейнер $CONTAINER_NAME уже существует"

        # Проверяем статус
        STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")
        if [ "$STATUS" != "running" ]; then
            print_info "Запускаем существующий контейнер..."
            docker start "$CONTAINER_NAME"
        else
            print_success "Контейнер уже запущен"
        fi
    else
        print_info "Создаем новый контейнер $CONTAINER_NAME..."

        # Собираем Docker образ
        print_info "Сборка Docker образа для $SERVICE_NAME..."
        docker build -t "myapp-$SERVICE_NAME:latest" \
            -f "$PROJECT_ROOT/docker/$SERVICE_NAME/Dockerfile" \
            "$PROJECT_ROOT/docker/$SERVICE_NAME"

        # Создаем и запускаем контейнер
        docker run -d \
            --name "$CONTAINER_NAME" \
            --network "$NETWORK_NAME" \
            -p "$PORT_MAPPING" \
            -e "SPRING_PROFILES_ACTIVE=dev" \
            --restart unless-stopped \
            "myapp-$SERVICE_NAME:latest"

        print_success "Контейнер $CONTAINER_NAME создан и запущен"
    fi

    # Показываем информацию о контейнере
    echo "-----------------------------------------"
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo "-----------------------------------------"
done

print_info "========================================="
print_success "Все контейнеры созданы и настроены!"
print_info "Для деплоя используйте: ./scripts/deploy-all.sh [profile]"
print_info "========================================="