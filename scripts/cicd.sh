#!/bin/bash
# cicd.sh - Полный CI/CD одной командой

set -e

ACTION="${1:-full}"
ENVIRONMENT="${2:-prod}"
TAG="${3:-latest}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[CICD]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_step() { echo -e "\n${BLUE}▶ $1${NC}"; }

# Авто-тег для dev
if [ "$ENVIRONMENT" = "dev" ] && [ "$TAG" = "latest" ]; then
    TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
fi

export TAG
export REGISTRY="${REGISTRY:-}"

case "$ACTION" in
    full)
        print_step "Полный CI/CD пайплайн: $ENVIRONMENT / $TAG"

        print_step "1. CI: Сборка образов"
        ./ci-build.sh

        print_step "2. CD: Деплой"
        ./cd-deploy.sh "$ENVIRONMENT" "$TAG" deploy

        print_success "CI/CD пайплайн завершен"
        ;;

    build-only)
        print_step "Только CI (сборка)"
        ./ci-build.sh
        ;;

    deploy-only)
        print_step "Только CD (деплой)"
        ./cd-deploy.sh "$ENVIRONMENT" "$TAG" deploy
        ;;

    rollback)
        print_step "Откат к версии: $TAG"
        ./cd-deploy.sh "$ENVIRONMENT" "$TAG" rollback
        ;;

    status)
        ./cd-deploy.sh "$ENVIRONMENT" "$TAG" status
        ;;

    *)
        echo "Использование:"
        echo "  ./cicd.sh full <env> <tag>      - Полный CI/CD"
        echo "  ./cicd.sh build-only            - Только сборка"
        echo "  ./cicd.sh deploy-only <env> <tag> - Только деплой"
        echo "  ./cicd.sh rollback <env> <tag>  - Откат"
        echo "  ./cicd.sh status <env>          - Статус сервисов"
        ;;
esac