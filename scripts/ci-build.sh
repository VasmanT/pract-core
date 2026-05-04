#!/bin/bash
# ci-build.sh - Только сборка и публикация образов

set -e

REGISTRY="${REGISTRY:-}"
TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo "latest")}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CI]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Сборка JAR
build_jars() {
    print_info "Сборка JAR файлов..."
    cd practice && mvn clean package -DskipTests && cd ..
    cd dbmicro && mvn clean package -DskipTests && cd ..
    print_success "JAR файлы собраны"
}

# Сборка Docker образов
build_images() {
    print_info "Сборка Docker образов с тегом: $TAG"
    docker build -t ${REGISTRY}practice:${TAG} -t ${REGISTRY}practice:latest ./practice
    docker build -t ${REGISTRY}dbmicro:${TAG} -t ${REGISTRY}dbmicro:latest ./dbmicro
    print_success "Образы собраны"
}

# Публикация в registry
push_images() {
    if [ -n "$REGISTRY" ]; then
        print_info "Публикация в $REGISTRY"
        docker push ${REGISTRY}practice:${TAG}
        docker push ${REGISTRY}practice:latest
        docker push ${REGISTRY}dbmicro:${TAG}
        docker push ${REGISTRY}dbmicro:latest
        print_success "Образы опубликованы"
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