#!/bin/bash
# test-kafka.sh - Тестирование Kafka из командной строки

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[KAFKA]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Настройки
TOPIC="${1:-test-topic}"
ACTION="${2:-produce}"
GROUP_ID="${3:-my-group}"

KAFKA_CONTAINER="myapp-kafka"

check_kafka() {
    if ! docker ps | grep -q "$KAFKA_CONTAINER"; then
        print_error "Kafka контейнер не запущен"
        print_info "Запустите: docker compose up -d"
        exit 1
    fi
    print_success "Kafka контейнер работает"
}

# Создание топика
create_topic() {
    print_info "Создание топика: $TOPIC"
    docker exec $KAFKA_CONTAINER kafka-topics.sh \
        --create \
        --topic "$TOPIC" \
        --bootstrap-server localhost:9092 \
        --partitions 3 \
        --replication-factor 1 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Топик '$TOPIC' создан"
    else
        print_info "Топик уже существует"
    fi
}

# Список топиков
list_topics() {
    print_info "Список всех топиков:"
    docker exec $KAFKA_CONTAINER kafka-topics.sh \
        --list \
        --bootstrap-server localhost:9092
}

# Информация о топике
describe_topic() {
    print_info "Информация о топике '$TOPIC':"
    docker exec $KAFKA_CONTAINER kafka-topics.sh \
        --describe \
        --topic "$TOPIC" \
        --bootstrap-server localhost:9092
}

# Отправка сообщений
produce_messages() {
    create_topic
    print_info "Запуск продюсера для топика '$TOPIC'"
    print_info "Введите сообщения (каждое с новой строки). Для выхода нажмите Ctrl+C"
    echo "----------------------------------------"

    docker exec -it $KAFKA_CONTAINER kafka-console-producer.sh \
        --topic "$TOPIC" \
        --bootstrap-server localhost:9092 \
        --property "parse.key=false" \
        --property "ignore.error=false"
}

# Чтение сообщений
consume_messages() {
    print_info "Запуск консюмера для топика '$TOPIC'"
    print_info "Чтение сообщений с начала (--from-beginning)"
    echo "----------------------------------------"

    docker exec -it $KAFKA_CONTAINER kafka-console-consumer.sh \
        --topic "$TOPIC" \
        --bootstrap-server localhost:9092 \
        --from-beginning
}

# Потребление с группой
consume_with_group() {
    print_info "Запуск консюмера с группой '$GROUP_ID' для топика '$TOPIC'"
    echo "----------------------------------------"

    docker exec -it $KAFKA_CONTAINER kafka-console-consumer.sh \
        --topic "$TOPIC" \
        --bootstrap-server localhost:9092 \
        --group "$GROUP_ID"
}

# Показать группы потребителей
list_groups() {
    print_info "Список групп потребителей:"
    docker exec $KAFKA_CONTAINER kafka-consumer-groups.sh \
        --list \
        --bootstrap-server localhost:9092
}

# Описание группы
describe_group() {
    print_info "Информация о группе '$GROUP_ID':"
    docker exec $KAFKA_CONTAINER kafka-consumer-groups.sh \
        --describe \
        --group "$GROUP_ID" \
        --bootstrap-server localhost:9092
}

case "$ACTION" in
    produce)
        check_kafka
        produce_messages
        ;;
    consume)
        check_kafka
        consume_messages
        ;;
    consume-group)
        check_kafka
        consume_with_group
        ;;
    list)
        check_kafka
        list_topics
        ;;
    describe)
        check_kafka
        describe_topic
        ;;
    groups)
        check_kafka
        list_groups
        ;;
    group-info)
        check_kafka
        describe_group
        ;;
    *)
        echo ""
        echo "Использование: ./test-kafka.sh [ТОПИК] [ДЕЙСТВИЕ] [ГРУППА]"
        echo ""
        echo "ДЕЙСТВИЯ:"
        echo "  produce         - Запустить продюсера (отправка сообщений)"
        echo "  consume         - Запустить консюмера (чтение всех сообщений)"
        echo "  consume-group   - Запустить консюмера с consumer group"
        echo "  list            - Показать все топики"
        echo "  describe        - Показать информацию о топике"
        echo "  groups          - Показать все группы потребителей"
        echo "  group-info      - Показать информацию о группе"
        echo ""
        echo "ПРИМЕРЫ:"
        echo "  ./test-kafka.sh my-topic produce                # Отправить сообщения"
        echo "  ./test-kafka.sh my-topic consume                # Прочитать сообщения"
        echo "  ./test-kafka.sh my-topic list                   # Список топиков"
        echo "  ./test-kafka.sh my-topic consume-group my-group # С группой"
        echo "  ./test-kafka.sh my-topic groups                 # Список групп"
        echo ""
        echo "ТЕСТ (продюсер и консюмер в разных терминалах):"
        echo "  Терминал 1: ./test-kafka.sh test produce"
        echo "  Терминал 2: ./test-kafka.sh test consume"
        echo ""
        ;;
esac

