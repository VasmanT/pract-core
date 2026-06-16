#!/bin/bash
# ci-build.sh - Только сборка и публикация образов

set -e

REGISTRY="${REGISTRY:-}"
TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo "latest")}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CI]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Определяем корневую директорию проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

print_info "Проект в: $PROJECT_ROOT"

# Сборка JAR
build_jars() {
    print_info "Сборка JAR файлов..."

    # Сборка practice
    if [ -d "practice" ]; then
        cd practice
        mvn clean package -DskipTests
        cd ..
        print_success "Модуль practice собран"
    else
        print_error "Папка practice не найдена"
        exit 1
    fi

    # Сборка dbmicro
    if [ -d "dbmicro" ]; then
        cd dbmicro
        mvn clean package -DskipTests
        cd ..
        print_success "Модуль dbmicro собран"
    else
        print_error "Папка dbmicro не найдена"
        exit 1
    fi

    # Сборка kafkamicro
    if [ -d "kafkamicro" ]; then
        cd kafkamicro
        mvn clean package -DskipTests
        cd ..
        print_success "Модуль kafkamicro собран"
    else
        print_warning "Папка kafkamicro не найдена, пропускаем"
    fi
}

# Сборка Docker образов
build_images() {
    print_info "Сборка Docker образов с тегом: $TAG"

    # Сборка practice
    if [ -f "practice/Dockerfile" ]; then
        docker build -t ${REGISTRY}practice:${TAG} -t ${REGISTRY}practice:latest ./practice
        print_success "Образ practice собран"
    else
        print_warning "Dockerfile для practice не найден"
    fi

    # Сборка dbmicro
    if [ -f "dbmicro/Dockerfile" ]; then
        docker build -t ${REGISTRY}dbmicro:${TAG} -t ${REGISTRY}dbmicro:latest ./dbmicro
        print_success "Образ dbmicro собран"
    else
        print_warning "Dockerfile для dbmicro не найден"
    fi

    # Сборка kafkamicro
    if [ -f "kafkamicro/Dockerfile" ]; then
        docker build -t ${REGISTRY}kafkamicro:${TAG} -t ${REGISTRY}kafkamicro:latest ./kafkamicro
        print_success "Образ kafkamicro собран"
    else
        print_warning "Dockerfile для kafkamicro не найден"
    fi

    print_success "Процесс сборки образов завершен"
}

# Публикация в registry
push_images() {
    if [ -n "$REGISTRY" ]; then
        print_info "Публикация в $REGISTRY"

        # Публикация practice
        if docker image inspect ${REGISTRY}practice:${TAG} &>/dev/null; then
            docker push ${REGISTRY}practice:${TAG}
            docker push ${REGISTRY}practice:latest
            print_success "practice опубликован"
        fi

        # Публикация dbmicro
        if docker image inspect ${REGISTRY}dbmicro:${TAG} &>/dev/null; then
            docker push ${REGISTRY}dbmicro:${TAG}
            docker push ${REGISTRY}dbmicro:latest
            print_success "dbmicro опубликован"
        fi

        # Публикация kafkamicro (ИСПРАВЛЕНО - ДОБАВЛЕНО)
        if docker image inspect ${REGISTRY}kafkamicro:${TAG} &>/dev/null; then
            docker push ${REGISTRY}kafkamicro:${TAG}
            docker push ${REGISTRY}kafkamicro:latest
            print_success "kafkamicro опубликован"
        fi

        print_success "Все образы опубликованы"
    fi
}

# Очистка мусорных образов
cleanup() {
    print_info "Удаление dangling образов"
    docker image prune -f
    print_success "Очистка завершена"
}

main() {
    echo "========== CI: BUILD ONLY =========="
    build_jars
    build_images
    push_images
    cleanup
    echo "========== CI FINISHED =========="
}

main "$@"