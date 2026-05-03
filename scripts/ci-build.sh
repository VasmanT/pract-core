#!/bin/bash
# ci-build.sh - Только CI: сборка и публикация образов

set -e

# Конфигурация
REGISTRY="${REGISTRY:-}"
TAG="${TAG:-$(git rev-parse --short HEAD)}"
VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"

# Цвета
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CI]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 1. Сборка JAR файлов
build_jars() {
    print_info "Сборка JAR файлов..."

    # Через Maven
    cd practice
    mvn clean package -DskipTests
    cd ..

    cd dbmicro
    mvn clean package -DskipTests
    cd ..

    print_success "JAR файлы собраны"
}

# 2. Сборка Docker образов
build_images() {
    print_info "Сборка Docker образов..."

    # Собираем с несколькими тегами
    docker build \
        -t ${REGISTRY}practice:${TAG} \
        -t ${REGISTRY}practice:latest \
        -t ${REGISTRY}practice:${VERSION} \
        ./practice

    docker build \
        -t ${REGISTRY}dbmicro:${TAG} \
        -t ${REGISTRY}dbmicro:latest \
        -t ${REGISTRY}dbmicro:${VERSION} \
        ./dbmicro

    print_success "Образы собраны:"
    echo "  - ${REGISTRY}practice:${TAG}"
    echo "  - ${REGISTRY}practice:${VERSION}"
    echo "  - ${REGISTRY}dbmicro:${TAG}"
    echo "  - ${REGISTRY}dbmicro:${VERSION}"
}

# 3. Тестирование образов
test_images() {
    print_info "Тестирование образов..."

    # Быстрый тест: запускаем и проверяем healthcheck
    docker run -d --name test-practice -p 8099:8095 ${REGISTRY}practice:${TAG}
    sleep 10

    if curl -f http://localhost:8099/actuator/health; then
        print_success "Образ practice прошел тест"
    else
        print_error "Образ practice не прошел тест"
        docker stop test-practice && docker rm test-practice
        exit 1
    fi

    docker stop test-practice && docker rm test-practice
}

# 4. Публикация в registry
push_images() {
    if [ -n "$REGISTRY" ]; then
        print_info "Публикация образов в $REGISTRY..."

        # Логин в registry (если нужна авторизация)
        if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
            echo "$DOCKER_PASSWORD" | docker login $REGISTRY -u "$DOCKER_USERNAME" --password-stdin
        fi

        # Push всех тегов
        docker push ${REGISTRY}practice:${TAG}
        docker push ${REGISTRY}practice:latest
        docker push ${REGISTRY}practice:${VERSION}
        docker push ${REGISTRY}dbmicro:${TAG}
        docker push ${REGISTRY}dbmicro:latest
        docker push ${REGISTRY}dbmicro:${VERSION}

        print_success "Образы опубликованы"
    else
        print_info "REGISTRY не указан, пропускаем публикацию"
    fi
}

# 5. Очистка
cleanup() {
    print_info "Очистка временных файлов..."

    # Удаляем JAR файлы (опционально)
    # rm -f practice/target/*.jar dbmicro/target/*.jar

    # Очищаем dangling образы
    docker image prune -f

    print_success "Очистка завершена"
}

# Главная функция CI
main() {
    echo "========================================="
    print_info "CI PIPELINE STARTED"
    print_info "Version: ${VERSION}"
    print_info "Commit: ${TAG}"
    print_info "Registry: ${REGISTRY:-local}"
    echo "========================================="

    build_jars
    build_images
    test_images
    push_images
    cleanup

    echo "========================================="
    print_success "CI PIPELINE FINISHED"
    echo "========================================="
}

main "$@"