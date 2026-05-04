#!/bin/bash
# cicd.sh - Полный CI/CD одной командой

set -e

ACTION="${1:-full}"
ENVIRONMENT="${2:-prod}"
TAG="${3:-latest}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CICD]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "\n${BLUE}▶ $1${NC}"; }

# Определяем корневую директорию
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Авто-тег для dev
if [ "$ENVIRONMENT" = "dev" ] && [ "$TAG" = "latest" ]; then
    TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
fi

export TAG
export REGISTRY="${REGISTRY:-}"

print_info "Проект: $PROJECT_ROOT"
print_info "Action: $ACTION | Environment: $ENVIRONMENT | Tag: $TAG"

case "$ACTION" in
    full)
        print_step "Полный CI/CD пайплайн: $ENVIRONMENT / $TAG"

        print_step "1. CI: Сборка образов"
        if [ -f "$SCRIPT_DIR/ci-build.sh" ]; then
            "$SCRIPT_DIR/ci-build.sh"
        else
            print_error "ci-build.sh не найден"
            exit 1
        fi

        print_step "2. CD: Деплой"
        if [ -f "$SCRIPT_DIR/cd-deploy.sh" ]; then
            "$SCRIPT_DIR/cd-deploy.sh" "$ENVIRONMENT" "$TAG" deploy
        else
            print_error "cd-deploy.sh не найден"
            exit 1
        fi

        print_success "CI/CD пайплайн завершен"
        ;;

    build-only)
        print_step "Только CI (сборка)"
        "$SCRIPT_DIR/ci-build.sh"
        ;;

    deploy-only)
        print_step "Только CD (деплой)"
        "$SCRIPT_DIR/cd-deploy.sh" "$ENVIRONMENT" "$TAG" deploy
        ;;

    rollback)
        print_step "Откат к версии: $TAG"
        "$SCRIPT_DIR/cd-deploy.sh" "$ENVIRONMENT" "$TAG" rollback
        ;;

    status)
        "$SCRIPT_DIR/cd-deploy.sh" "$ENVIRONMENT" "$TAG" status
        ;;

    help|--help|-h)
        echo "Использование: ./cicd.sh [ACTION] [ENVIRONMENT] [TAG]"
        echo ""
        echo "Действия:"
        echo "  full         - Полный CI/CD (сборка + деплой)"
        echo "  build-only   - Только сборка образов"
        echo "  deploy-only  - Только деплой"
        echo "  rollback     - Откат к версии"
        echo "  status       - Статус сервисов"
        echo ""
        echo "Примеры:"
        echo "  ./cicd.sh full prod v1.0.0"
        echo "  ./cicd.sh build-only"
        echo "  ./cicd.sh deploy-only dev latest"
        echo "  ./cicd.sh status prod"
        ;;

    *)
        print_error "Неизвестное действие: $ACTION"
        echo "Используйте ./cicd.sh help для справки"
        exit 1
        ;;
esac