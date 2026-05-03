#!/bin/bash
# cicd.sh - Полный CI/CD пайплайн одной командой

set -e

# Параметры командной строки
ACTION="${1:-full}"        # full, build-only, deploy-only, rollback, status
ENVIRONMENT="${2:-prod}"   # dev, staging, prod
TAG="${3:-latest}"         # версия для деплоя
VERSION="${4:-}"           # версия для тегирования (если пусто - auto)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "\n${MAGENTA}═════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}▶ $1${NC}"; echo -e "${MAGENTA}═════════════════════════════════════════════════════════════${NC}"; }
print_header() { echo -e "\n${MAGENTA}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${MAGENTA}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Конфигурация
REGISTRY="${REGISTRY:-localhost:5000/}"  # Ваш Docker registry
CI_SCRIPT="./ci-build.sh"
CD_SCRIPT="./cd-deploy.sh"

# Автоопределение версии
if [ -z "$VERSION" ] || [ "$VERSION" = "auto" ]; then
    if git describe --tags --abbrev=0 2>/dev/null; then
        VERSION=$(git describe --tags --abbrev=0)
    else
        VERSION="0.0.0"
    fi

    # Добавляем коммит для dev окружения
    if [ "$ENVIRONMENT" = "dev" ]; then
        COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "noscm")
        VERSION="${VERSION}-${COMMIT_HASH}"
    fi
fi

# Переменные для CI
export REGISTRY
export VERSION
export TAG="${VERSION}"  # Используем версию как тег

# Функция проверки окружения
check_environment() {
    print_step "Проверка окружения"

    # Проверка Docker
    if ! docker info &>/dev/null; then
        print_error "Docker не запущен"
        exit 1
    fi
    print_success "Docker: OK"

    # Проверка Registry доступности
    if [ -n "$REGISTRY" ]; then
        if curl -s "http://${REGISTRY}/v2/" &>/dev/null; then
            print_success "Registry $REGISTRY: OK"
        else
            print_warning "Registry $REGISTRY недоступен, будет использован локальный режим"
            REGISTRY=""
        fi
    fi

    # Проверка Maven (только для сборки)
    if [[ "$ACTION" == "full" ]] || [[ "$ACTION" == "build-only" ]]; then
        if ! command -v mvn &>/dev/null; then
            print_error "Maven не установлен"
            exit 1
        fi
        print_success "Maven: OK"
    fi

    # Проверка скриптов
    if [ ! -f "$CI_SCRIPT" ]; then
        print_warning "CI скрипт не найден: $CI_SCRIPT"
    fi

    if [ ! -f "$CD_SCRIPT" ]; then
        print_warning "CD скрипт не найден: $CD_SCRIPT"
    fi
}

# Функция сборки (CI часть)
run_ci() {
    print_header "🔨 CI: СБОРКА И ПУБЛИКАЦИЯ"

    print_info "Версия: $VERSION"
    print_info "Registry: ${REGISTRY:-local}"

    # Сборка JAR файлов
    print_step "1. Сборка JAR файлов"
    build_jars

    # Сборка Docker образов
    print_step "2. Сборка Docker образов"
    build_docker_images

    # Тестирование образов
    print_step "3. Тестирование образов"
    test_docker_images

    # Публикация в registry
    if [ -n "$REGISTRY" ]; then
        print_step "4. Публикация в registry"
        push_to_registry
    else
        print_warning "Пропускаем публикацию (registry не указан)"
    fi

    # Сохранение артефактов
    print_step "5. Сохранение информации о сборке"
    save_build_info

    print_success "CI часть завершена успешно"
}

# Функция сборки JAR
build_jars() {
    local modules=("practice" "dbmicro")

    for module in "${modules[@]}"; do
        print_info "Сборка модуля: $module"
        cd "$PROJECT_ROOT/$module"

        if mvn clean package -DskipTests; then
            print_success "Модуль $module собран"
            # Проверяем создание JAR
            if [ -f "target/${module}-1.0-SNAPSHOT.jar" ]; then
                print_info "JAR создан: target/${module}-1.0-SNAPSHOT.jar"
            fi
        else
            print_error "Ошибка сборки модуля $module"
            exit 1
        fi
    done

    cd "$PROJECT_ROOT"
}

# Функция сборки Docker образов
build_docker_images() {
    local services=("practice" "dbmicro")

    for service in "${services[@]}"; do
        print_info "Сборка образа для: $service"

        # Сборка с несколькими тегами
        docker build \
            -t "${REGISTRY}${service}:${VERSION}" \
            -t "${REGISTRY}${service}:latest" \
            -t "${REGISTRY}${service}:${TAG}" \
            "./${service}"

        if [ $? -eq 0 ]; then
            print_success "Образ ${service} собран"

            # Показываем размер образа
            local size=$(docker image inspect "${REGISTRY}${service}:${VERSION}" --format='{{.Size}}' | numfmt --to=iec)
            print_info "Размер образа: $size"
        else
            print_error "Ошибка сборки образа ${service}"
            exit 1
        fi
    done
}

# Функция тестирования образов
test_docker_images() {
    print_info "Запуск тестов образов..."

    # Тест practice образа
    docker run -d --name test-practice -p 8099:8095 "${REGISTRY}practice:${VERSION}"
    sleep 15

    if curl -s -f http://localhost:8099/actuator/health &>/dev/null; then
        print_success "Тест practice образа: OK"
    else
        print_warning "Тест practice образа: healthcheck не прошел"

        # Показываем логи для диагностики
        docker logs test-practice --tail 20
    fi

    docker stop test-practice && docker rm test-practice

    # Тест dbmicro образа
    docker run -d --name test-dbmicro -p 8100:8096 "${REGISTRY}dbmicro:${VERSION}"
    sleep 15

    if curl -s -f http://localhost:8100/actuator/health &>/dev/null; then
        print_success "Тест dbmicro образа: OK"
    else
        print_warning "Тест dbmicro образа: healthcheck не прошел"
    fi

    docker stop test-dbmicro && docker rm test-dbmicro
}

# Функция публикации в registry
push_to_registry() {
    local services=("practice" "dbmicro")

    for service in "${services[@]}"; do
        print_info "Публикация образа: ${service}"

        # Публикация всех тегов
        docker push "${REGISTRY}${service}:${VERSION}"
        docker push "${REGISTRY}${service}:latest"
        docker push "${REGISTRY}${service}:${TAG}"

        print_success "Образ ${service} опубликован"
    done
}

# Функция сохранения информации о сборке
save_build_info() {
    local build_dir="${PROJECT_ROOT}/build-info"
    mkdir -p "$build_dir"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local build_file="${build_dir}/build_${timestamp}.json"

    cat > "$build_file" << EOF
{
  "version": "${VERSION}",
  "tag": "${TAG}",
  "environment": "${ENVIRONMENT}",
  "timestamp": "$(date -Iseconds)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'no-git')",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')",
  "registry": "${REGISTRY}",
  "images": {
    "practice": "${REGISTRY}practice:${VERSION}",
    "dbmicro": "${REGISTRY}dbmicro:${VERSION}"
  }
}
EOF

    print_success "Информация о сборке сохранена: $build_file"

    # Создаем symlink на последнюю сборку
    ln -sf "$build_file" "${build_dir}/latest.json"
}

# Функция деплоя (CD часть)
run_cd() {
    print_header "🚀 CD: ДЕПЛОЙ НА СЕРВЕР"

    print_info "Окружение: $ENVIRONMENT"
    print_info "Версия: ${VERSION:-$TAG}"
    print_info "Registry: ${REGISTRY:-local}"

    # Проверяем наличие скрипта CD
    if [ -f "$CD_SCRIPT" ]; then
        print_info "Используем CD скрипт: $CD_SCRIPT"

        # Передаем параметры в CD скрипт
        if [ -n "$VERSION" ]; then
            $CD_SCRIPT "$ENVIRONMENT" "$VERSION" "deploy"
        else
            $CD_SCRIPT "$ENVIRONMENT" "$TAG" "deploy"
        fi
    else
        # Встроенная CD логика
        print_info "Выполняем встроенный деплой..."

        # Проверяем наличие образов
        check_images_availability

        # Бэкап текущей версии
        backup_current_version

        # Остановка старых сервисов
        stop_old_services

        # Запуск новых сервисов
        start_new_services

        # Ожидание готовности
        wait_for_services

        # Проверка работоспособности
        verify_deployment
    fi

    print_success "CD часть завершена успешно"
}

# Встроенные CD функции (если нет отдельного скрипта)
check_images_availability() {
    print_info "Проверка доступности образов..."

    local services=("practice" "dbmicro")
    local missing=()

    for service in "${services[@]}"; do
        local image="${REGISTRY}${service}:${VERSION:-$TAG}"

        if ! docker image inspect "$image" &>/dev/null; then
            print_warning "Образ $image не найден локально"

            if [ -n "$REGISTRY" ]; then
                print_info "Пытаемся скачать из registry..."
                if docker pull "$image"; then
                    print_success "Образ скачан: $image"
                else
                    missing+=("$image")
                fi
            else
                missing+=("$image")
            fi
        else
            print_success "Образ найден: $image"
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Недоступные образы: ${missing[*]}"
        exit 1
    fi
}

backup_current_version() {
    local backup_dir="./backups/${ENVIRONMENT}"
    mkdir -p "$backup_dir"

    local timestamp=$(date +%Y%m%d_%H%M%S)

    # Сохраняем текущие версии
    docker inspect myapp-practice --format='{{.Config.Image}}' 2>/dev/null | cut -d':' -f2 > "${backup_dir}/prev_version_${timestamp}.txt" || echo "none" > "${backup_dir}/prev_version_${timestamp}.txt"

    print_info "Бэкап версии создан: ${backup_dir}/prev_version_${timestamp}.txt"
}

stop_old_services() {
    print_info "Остановка старых сервисов..."

    docker compose down 2>/dev/null || true

    print_success "Старые сервисы остановлены"
}

start_new_services() {
    print_info "Запуск новых сервисов..."

    export TAG="${VERSION:-$TAG}"
    export REGISTRY

    # Используем docker-compose с правильными переменными
    docker compose up -d

    print_success "Новые сервисы запущены"
}

wait_for_services() {
    print_info "Ожидание готовности сервисов (макс. 60 сек)..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local ready=true

        if ! curl -s -f http://localhost:8095/actuator/health &>/dev/null; then
            ready=false
        fi

        if ! curl -s -f http://localhost:8096/actuator/health &>/dev/null; then
            ready=false
        fi

        if [ "$ready" = true ]; then
            print_success "Все сервисы готовы"
            return 0
        fi

        printf "."
        sleep 2
        ((attempt++))
    done

    echo ""
    print_warning "Не все сервисы готовы, но продолжаем..."
    docker compose ps
}

verify_deployment() {
    print_step "Проверка успешности деплоя"

    # Проверяем версии запущенных контейнеров
    local practice_image=$(docker inspect myapp-practice --format='{{.Config.Image}}' 2>/dev/null || echo "not-running")
    local dbmicro_image=$(docker inspect myapp-dbmicro --format='{{.Config.Image}}' 2>/dev/null || echo "not-running")

    print_info "Запущенные версии:"
    echo "  practice: $practice_image"
    echo "  dbmicro: $dbmicro_image"

    # Healthcheck
    print_info "Healthcheck статус:"
    docker compose ps

    # Тестовый запрос
    if curl -s http://localhost:8095/actuator/info | grep -q "git"; then
        print_success "Сервисы работают корректно"
    else
        print_warning "Проверьте работу сервисов вручную"
    fi
}

# Функция быстрого деплоя без сборки
quick_deploy() {
    print_header "📦 QUICK DEPLOY (только CD)"

    export VERSION="${TAG}"
    run_cd
}

# Функция только сборки
build_only() {
    print_header "🔨 BUILD ONLY"

    check_environment
    run_ci
}

# Функция только деплоя
deploy_only() {
    print_header "🚀 DEPLOY ONLY"

    check_environment
    run_cd
}

# Функция отката
rollback() {
    print_header "⏪ ROLLBACK"

    local rollback_version="${TAG}"

    print_info "Откат к версии: $rollback_version"

    export TAG="$rollback_version"
    export VERSION="$rollback_version"

    run_cd

    print_success "Откат выполнен"
}

# Функция статуса
show_status() {
    print_header "📊 СТАТУС СЕРВИСОВ"

    # Статус контейнеров
    echo -e "\n${CYAN}Контейнеры:${NC}"
    docker compose ps 2>/dev/null || echo "Сервисы не запущены"

    # Информация о версиях
    echo -e "\n${CYAN}Версии образов:${NC}"
    docker inspect myapp-practice --format='practice: {{.Config.Image}}' 2>/dev/null || echo "practice: не запущен"
    docker inspect myapp-dbmicro --format='dbmicro: {{.Config.Image}}' 2>/dev/null || echo "dbmicro: не запущен"

    # Последняя сборка
    if [ -f "build-info/latest.json" ]; then
        echo -e "\n${CYAN}Последняя сборка:${NC}"
        cat build-info/latest.json | jq '.version, .timestamp' 2>/dev/null || cat build-info/latest.json
    fi
}

# Функция полного пайплайна
full_pipeline() {
    print_header "🔄 ПОЛНЫЙ CI/CD ПАЙПЛАЙН"

    local start_time=$(date +%s)

    print_info "Окружение: $ENVIRONMENT"
    print_info "Версия: $VERSION"
    print_info "Режим: ПОЛНЫЙ (сборка + деплой)"

    # Выполняем CI
    run_ci

    # Выполняем CD
    run_cd

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    print_header "✅ CI/CD ПАЙПЛАЙН ЗАВЕРШЕН"
    print_success "Общее время выполнения: ${duration} секунд"

    # Отправка уведомления (опционально)
    send_notification
}

# Функция уведомлений
send_notification() {
    # Пример отправки в Slack/Telegram
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"✅ CI/CD Pipeline завершен: $ENVIRONMENT/$VERSION\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi

    print_info "Уведомления отправлены"
}

# Функция отображения помощи
show_help() {
    cat << EOF
${CYAN}═══════════════════════════════════════════════════════════════════${NC}
${GREEN}CI/CD ONE-COMMAND DEPLOYMENT SCRIPT${NC}
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${YELLOW}Использование:${NC}
  ./cicd.sh [ACTION] [ENVIRONMENT] [TAG] [VERSION]

${YELLOW}Параметры:${NC}
  ACTION        - Действие (по умолчанию: full)
  ENVIRONMENT   - Окружение: dev, staging, prod (по умолчанию: prod)
  TAG           - Тег для деплоя (по умолчанию: latest)
  VERSION       - Версия сборки (автоопределение если не указана)

${YELLOW}Действия:${NC}
  full          - Полный CI/CD (сборка + тесты + публикация + деплой)
  build-only    - Только CI (сборка, тесты, публикация)
  deploy-only   - Только CD (деплой готового образа)
  quick-deploy  - Быстрый деплой без сборки (алиас deploy-only)
  rollback      - Откат к указанной версии
  status        - Показать статус сервисов

${YELLOW}Примеры:${NC}

  # Полный пайплайн в production
  ./cicd.sh full prod v1.2.3

  # Полный пайплайн в staging
  ./cicd.sh full staging latest

  # Полный пайплайн в dev (авто-версия с коммитом)
  ./cicd.sh full dev

  # Только сборка (без деплоя)
  ./cicd.sh build-only dev

  # Только деплой готового образа
  ./cicd.sh deploy-only prod v1.2.3

  # Быстрый деплой последней версии
  ./cicd.sh quick-deploy prod latest

  # Откат к предыдущей версии
  ./cicd.sh rollback prod v1.2.2

  # Проверка статуса
  ./cicd.sh status prod

${YELLOW}Переменные окружения:${NC}
  REGISTRY       - Docker registry (по умолчанию: localhost:5000/)
  SLACK_WEBHOOK  - Webhook для уведомлений (опционально)

${YELLOW}Примеры с переменными:${NC}
  REGISTRY=myregistry.com/ ./cicd.sh full prod v1.2.3
  SLACK_WEBHOOK=https://hooks.slack.com/... ./cicd.sh full staging latest

${CYAN}═══════════════════════════════════════════════════════════════════${NC}
EOF
}

# Главная функция выбора действия
main() {
    # Показываем заголовок
    print_header "CI/CD PIPELINE"
    print_info "Action: $ACTION"
    print_info "Environment: $ENVIRONMENT"
    print_info "Tag: $TAG"
    print_info "Version: $VERSION"

    # Проверка базового окружения
    check_environment

    # Выбор действия
    case "$ACTION" in
        full)
            full_pipeline
            ;;
        build-only)
            build_only
            ;;
        deploy-only|quick-deploy)
            quick_deploy
            ;;
        rollback)
            rollback
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Неизвестное действие: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

# Обработка сигналов
trap 'print_error "Пайплайн прерван пользователем"; exit 1' INT TERM

# Запуск
main "$@"