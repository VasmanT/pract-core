#!/bin/bash

set -e

# Параметры по умолчанию
CONTAINER_ID="${1:-9ea}"
PROJECT_ROOT="$(cd .. && pwd)"  # Переходим на уровень выше от scripts/
JAR_PATH="${2:-$PROJECT_ROOT/target/dbmicro-1.0-SNAPSHOT.jar}"
TARGET_PATH="/app/app.jar"
#PROFILE="${3:-prod}"  # Профиль по умолчанию: prod
#PROFILE="${3:-dev}"  # Профиль по умолчанию: prod

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

check_dependencies() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен или не найден в PATH"
        exit 1
    fi

    if ! command -v mvn &> /dev/null; then
        print_error "Maven не установлен или не найден в PATH"
        exit 1
    fi
}

check_jar_file() {
    if [ ! -f "$JAR_PATH" ]; then
        print_error "JAR файл не найден: $JAR_PATH"
        print_error "Проверьте путь и выполните сборку вручную"
        exit 1
    fi
}

main() {
    print_info "=== Начало деплоя приложения ==="

    check_dependencies

    # Останавливаем контейнер
    print_info "1. Останавливаем контейнер $CONTAINER_ID..."
    if docker stop "$CONTAINER_ID" &> /dev/null; then
        print_success "Контейнер остановлен"
    else
        print_warning "Контейнер $CONTAINER_ID не был найден или уже остановлен"
    fi

    # Собираем проект Maven из корневой директории проекта
    print_info "2. Собираем проект Maven..."
    cd "$PROJECT_ROOT"  # Переходим в корень проекта где есть pom.xml
    mvn clean package -DskipTests
    print_success "Сборка Maven завершена"

    # Проверяем что JAR файл создан
    check_jar_file

    # Копируем JAR файл в контейнер
    print_info "3. Копируем JAR файл в контейнер..."
    docker cp "$JAR_PATH" "${CONTAINER_ID}:${TARGET_PATH}"
    print_success "Файл скопирован в контейнер"

    # Останавливаем контейнер
    print_info "4. Останавливаем контейнер для изменения конфигурации..."
    docker stop "$CONTAINER_ID"

#    # Запускаем контейнер
#    print_info "4. Запускаем контейнер $CONTAINER_ID..."
#    docker start "$CONTAINER_ID"
#    print_success "Контейнер запущен"
#
#    print_success "=== Деплой успешно завершен! ==="
#    print_info "Контейнер $CONTAINER_ID запущен с обновленной версией приложения"

    # Запускаем контейнер с новыми параметрами
    print_info "5. Запускаем контейнер $CONTAINER_ID с профилем $PROFILE..."

    # Запускаем контейнер с нужными параметрами
    docker start "$CONTAINER_ID"


# Запускаем контейнер с профилем
#    print_info "5. Запускаем контейнер $CONTAINER_ID с профилем $PROFILE..."
#    docker start "$CONTAINER_ID"
#
#    # Ждем немного для запуска контейнера
#    sleep 2
#
##    # Запускаем приложение внутри контейнера с указанным профилем
#    print_info "6. Запускаем приложение внутри контейнера..."
#    docker exec -d "$CONTAINER_ID" java -jar $TARGET_PATH --spring.profiles.active=$PROFILE
##
#    print_success "=== Деплой успешно завершен! ==="
#    print_info "Контейнер $CONTAINER_ID запущен с профилем $PROFILE"
#    print_info "Для проверки выполните:"
#    print_info "  docker logs $CONTAINER_ID"
#    print_info "  curl http://localhost:8089/api/info/profile"

    # Изменяем команду запуска внутри контейнера
    print_info "6. Настраиваем запуск приложения с профилем $PROFILE..."

    # Создаем скрипт запуска с профилем
    DOCKER_EXEC_CMD="java -jar $TARGET_PATH --spring.profiles.active=$PROFILE"
    docker exec "$CONTAINER_ID" sh -c "echo '$DOCKER_EXEC_CMD' > /app/start.sh && chmod +x /app/start.sh"

    # Останавливаем текущий процесс если он есть
    docker exec "$CONTAINER_ID" pkill -f "java.*jar" || true

    # Запускаем новый процесс
    docker exec -d "$CONTAINER_ID" /app/start.sh

    print_success "=== Деплой успешно завершен! ==="
    print_info "Проверьте логи: docker logs $CONTAINER_ID"
    print_info "Проверьте процесс: docker exec $CONTAINER_ID ps aux"

}

main "$@"