#!/bin/bash

set -e

# Параметры
CONTAINER_ID="${1:-eaa4}"
PROJECT_ROOT="$(cd .. && pwd)"
JAR_PATH="${PROJECT_ROOT}/target/practice-1.0-SNAPSHOT.jar"
PROFILE="${2:-prod}"
#PROFILE="${2:-dev}"
SERVICE_PORT="8095"  # Порт вашего Spring приложения
HEALTH_CHECK_MAX_ATTEMPTS=30  # Максимальное количество попыток проверки
HEALTH_CHECK_INTERVAL=2  # Интервал между проверками в секундах

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции вывода
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."

    local missing_deps=()

    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        print_success "Docker: установлен ($(docker --version | head -n1))"
    fi

    if ! command -v mvn &> /dev/null; then
        missing_deps+=("maven")
    else
        print_success "Maven: установлен ($(mvn --version | head -n1))"
    fi

    # Проверяем Java внутри контейнера
    if ! docker exec "$CONTAINER_ID" sh -c "command -v java" &> /dev/null; then
        print_warning "Java не найдена в контейнере $CONTAINER_ID"
        print_info "Проверка Java на хосте..."
        if ! command -v java &> /dev/null; then
            missing_deps+=("java")
        else
            print_success "Java: установлена на хосте ($(java -version 2>&1 | head -n1))"
        fi
    else
        print_success "Java: установлена в контейнере"
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Отсутствуют необходимые зависимости: ${missing_deps[*]}"
        print_error "Установите их и попробуйте снова"
        exit 1
    fi

    # Проверка, запущен ли Docker демон
    if ! docker info &> /dev/null; then
        print_error "Docker демон не запущен или нет прав доступа"
        print_error "Запустите Docker или добавьте пользователя в группу docker"
        exit 1
    fi
}

# Проверка существования контейнера
check_container_exists() {
    if ! docker inspect "$CONTAINER_ID" &> /dev/null; then
        print_error "Контейнер $CONTAINER_ID не существует"
        print_info "Доступные контейнеры:"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | head -20
        exit 1
    fi
    print_success "Контейнер $CONTAINER_ID найден"
}

# Проверка состояния сервиса
check_service_health() {
    print_info "Проверка состояния сервиса..."

    local attempt=1
    local service_url="http://localhost:$SERVICE_PORT"

    print_info "URL для проверки: $service_url"
    print_info "Доступные endpoints:"
    print_info "  - $service_url/api/players/getdata"
    print_info "  - $service_url/api/info/profile"
    print_info "  - $service_url/actuator/health"
    print_info "Ожидание запуска сервиса (макс. $((HEALTH_CHECK_MAX_ATTEMPTS * HEALTH_CHECK_INTERVAL)) сек.)..."

    while [ $attempt -le $HEALTH_CHECK_MAX_ATTEMPTS ]; do
        # Проверяем процесс Java внутри контейнера
        if docker exec "$CONTAINER_ID" pgrep -f "java.*app.jar" &> /dev/null; then
            print_success "Попытка $attempt: Java процесс запущен в контейнере"

            # Пробуем сделать HTTP запрос к сервису
            local curl_success=false

            # Вариант 1: Проверяем /api/players/getdata
            if curl -s -f --max-time 5 "$service_url/api/players/getdata" &> /dev/null; then
                print_success "Сервис отвечает на: $service_url/api/players/getdata"
                curl_success=true
            fi

            # Вариант 2: Проверяем /api/info/profile
            if curl -s -f --max-time 5 "$service_url/api/info/profile" &> /dev/null; then
                print_success "Сервис отвечает на: $service_url/api/info/profile"
                curl_success=true
            fi

            # Вариант 3: Проверяем корневой URL
            if curl -s -f --max-time 5 "$service_url" &> /dev/null; then
                print_success "Сервис отвечает на корневой URL: $service_url"
                curl_success=true
            fi

            # Вариант 4: Проверяем actuator health
            if curl -s -f --max-time 5 "$service_url/actuator/health" &> /dev/null; then
                print_success "Сервис отвечает на: $service_url/actuator/health"
                curl_success=true
            fi

            # Если хотя бы один запрос успешен
            if [ "$curl_success" = true ]; then
                print_success "Сервис успешно запущен и отвечает на HTTP запросы"

                # Дополнительная проверка профиля
                print_info "Проверка активного профиля..."
                if docker exec "$CONTAINER_ID" ps aux | grep -q "spring.profiles.active=$PROFILE"; then
                    print_success "Приложение запущено с профилем: $PROFILE"
                else
                    print_warning "Не удалось подтвердить профиль в командной строке"
                fi

                # Проверка ответа от профиля
                print_info "Получение информации о профиле..."
                local profile_response=$(curl -s --max-time 5 "$service_url/api/info/profile" 2>/dev/null || echo "")
                if [ -n "$profile_response" ]; then
                    print_success "Ответ от сервиса: $profile_response"
                fi

                # Показываем информацию о сервисе
                print_info "=== ИНФОРМАЦИЯ О СЕРВИСЕ ==="
                print_info "Контейнер: $CONTAINER_ID"
                print_info "Профиль: $PROFILE"
                print_info "Порт: $SERVICE_PORT"
                print_info "Статус контейнера: $(docker inspect -f '{{.State.Status}}' "$CONTAINER_ID")"
                print_info "Время запуска: $(docker inspect -f '{{.State.StartedAt}}' "$CONTAINER_ID" | cut -d. -f1)"
                print_info "IP адрес: $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_ID")"
                print_info "Проброшенные порты: $(docker port "$CONTAINER_ID" 2>/dev/null || echo "не настроены")"
                print_info "=== КОМАНДЫ ДЛЯ УПРАВЛЕНИЯ ==="
                print_info "Логи:              docker logs $CONTAINER_ID"
                print_info "Логи (последние): docker logs --tail 20 $CONTAINER_ID"
                print_info "Логи (следить):   docker logs -f $CONTAINER_ID"
                print_info "Остановка:        docker stop $CONTAINER_ID"
                print_info "Перезапуск:       docker restart $CONTAINER_ID"
                print_info "Войти в контейнер: docker exec -it $CONTAINER_ID sh"
                print_info "Проверить процесс: docker exec $CONTAINER_ID ps aux"
                print_info "=== ТЕСТИРОВАНИЕ API ==="
                print_info "curl $service_url/api/info/profile"
                print_info "curl $service_url/api/players/getdata"
                print_info "curl $service_url/actuator/health"

                return 0
            else
                print_info "Попытка $attempt/$HEALTH_CHECK_MAX_ATTEMPTS: Сервис не отвечает на HTTP запросы, ждем..."
                print_info "Проверяем процессы внутри контейнера..."
                docker exec "$CONTAINER_ID" ps aux | head -10
            fi
        else
            print_info "Попытка $attempt/$HEALTH_CHECK_MAX_ATTEMPTS: Java процесс не найден, ждем..."
        fi

        sleep $HEALTH_CHECK_INTERVAL
        ((attempt++))
    done

    print_error "Сервис не запустился за отведенное время"
    print_error "=== ДИАГНОСТИКА ==="
    print_error "1. Проверьте логи: docker logs $CONTAINER_ID"
    print_error "2. Проверьте процессы: docker exec $CONTAINER_ID ps aux"
    print_error "3. Проверьте порты: docker port $CONTAINER_ID"
    print_error "4. Проверьте сеть: docker inspect $CONTAINER_ID | grep -A10 NetworkSettings"
    print_error "5. Проверьте запуск Java: docker exec $CONTAINER_ID sh -c 'ps aux | grep java'"

    # Показываем последние логи для диагностики
    print_error "=== ПОСЛЕДНИЕ ЛОГИ (20 строк) ==="
    docker logs --tail 20 "$CONTAINER_ID" 2>/dev/null || print_error "Не удалось получить логи"

    print_error "=== СОСТОЯНИЕ КОНТЕЙНЕРА ==="
    docker inspect --format='{{json .State}}' "$CONTAINER_ID" | python3 -m json.tool 2>/dev/null || \
    docker inspect "$CONTAINER_ID" | grep -A5 "State"

    return 1
}

# Проверка порта
check_port_availability() {
    print_info "Проверка доступности порта $SERVICE_PORT..."

    # Проверяем, слушает ли что-то порт внутри контейнера
    if docker exec "$CONTAINER_ID" sh -c "command -v ss && ss -tlnp | grep :$SERVICE_PORT || netstat -tlnp 2>/dev/null | grep :$SERVICE_PORT || true" | grep -q ":$SERVICE_PORT"; then
        print_success "Порт $SERVICE_PORT используется внутри контейнера"
    else
        print_warning "Порт $SERVICE_PORT не слушается внутри контейнера"
    fi

    # Проверяем проброшен ли порт на хост
    if docker port "$CONTAINER_ID" | grep -q "$SERVICE_PORT"; then
        local host_port=$(docker port "$CONTAINER_ID" $SERVICE_PORT/tcp 2>/dev/null | cut -d: -f2)
        print_success "Порт проброшен на хост: $host_port"
    fi
}

# Основная функция
main() {
    echo "========================================="
    print_info "=== Начало деплоя приложения ==="
    print_info "Контейнер: $CONTAINER_ID"
    print_info "Профиль: $PROFILE"
    print_info "JAR: $JAR_PATH"
    echo "========================================="

    # Проверка зависимостей
    check_dependencies

    # Проверка существования контейнера
    check_container_exists

    # Сборка проекта
    print_info "1. Собираем проект Maven..."
    cd "$PROJECT_ROOT"
    if mvn clean package -DskipTests; then
        print_success "Сборка Maven завершена успешно"
    else
        print_error "Ошибка при сборке Maven"
        exit 1
    fi

    # Проверка JAR файла
    if [ ! -f "$JAR_PATH" ]; then
        print_error "JAR файл не найден: $JAR_PATH"
        print_error "Возможные пути:"
        find "$PROJECT_ROOT/target" -name "*.jar" 2>/dev/null || true
        exit 1
    fi
    print_success "JAR файл найден: $(ls -lh "$JAR_PATH")"

    # Остановка контейнера
    print_info "2. Останавливаем контейнер $CONTAINER_ID..."
    if docker stop "$CONTAINER_ID" &> /dev/null; then
        print_success "Контейнер остановлен"
    else
        print_warning "Контейнер уже остановлен или не найден"
    fi

    # Копирование JAR файла
    print_info "3. Копируем JAR файл в контейнер..."
    if docker cp "$JAR_PATH" "${CONTAINER_ID}:/app/app.jar"; then
        print_success "JAR файл успешно скопирован в контейнер"
                print_success "$JAR_PATH"
                print_success "${CONTAINER_ID}"
    else
        print_error "Ошибка при копировании JAR файла"
        exit 1
    fi

    # Запуск контейнера
    print_info "4. Запускаем контейнер..."
    if docker start "$CONTAINER_ID"; then
        print_success "Контейнер запущен"
    else
        print_error "Ошибка при запуске контейнера"
        exit 1
    fi

    # Ждем запуска контейнера
    sleep 2

    # Запуск приложения внутри контейнера
    print_info "5. Запускаем приложение с профилем '$PROFILE'..."
    if docker exec -d "$CONTAINER_ID" sh -c "pkill -f 'java.*jar' 2>/dev/null || true; java -jar /app/app.jar --spring.profiles.active=$PROFILE"; then
        print_success "Команда запуска приложения выполнена"
    else
        print_error "Ошибка при запуске приложения"
    fi

    echo "========================================="
    print_info "=== Проверка состояния сервиса ==="
    echo "========================================="

    # Проверка порта
    check_port_availability

    # Проверка состояния сервиса
    if check_service_health; then
        echo "========================================="
        print_success "=== ДЕПЛОЙ УСПЕШНО ЗАВЕРШЕН! ==="
        print_success "Сервис запущен и работает корректно"
        echo "========================================="
    else
        echo "========================================="
        print_warning "=== ДЕПЛОЙ ЗАВЕРШЕН С ПРЕДУПРЕЖДЕНИЯМИ ==="
        print_warning "Сервис может быть не полностью работоспособен"
        print_warning "Проверьте логи для деталей: docker logs $CONTAINER_ID"
        echo "========================================="
        exit 1
    fi
        # Проверка порта
        check_port_availability
}

    if curl -s -f --max-time 5 "http://localhost:8089/api/info/profile"  &>  /dev/null; then
                    echo "Сервис отвечает на: http://localhost:8089/api/info/profile+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
                    echo curl_success=true
                    curl_success=true
                    else
                                        echo "Не удалось подтвердить профиль в командной строке +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    fi


# Обработка ошибок
trap 'print_error "Скрипт прерван пользователем (Ctrl+C)"; exit 1' INT
trap 'print_error "Произошла ошибка выполнения"; exit 1' ERR

# Запуск основного скрипта
main "$@"

