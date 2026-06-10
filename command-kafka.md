Подключение к контейнеру Kafka
bash
# Войти в контейнер Kafka
docker exec -it myapp-kafka bash

# Или выполнять команды напрямую (без входа)
docker exec -it myapp-kafka kafka-<команда> --параметры
2️⃣ Управление топиками (Topics)
bash
# === Просмотр ===
# Список всех топиков
kafka-topics --list --bootstrap-server localhost:9092

# Детальная информация о топике
kafka-topics --describe --topic my-topic --bootstrap-server localhost:9092

# === Создание ===
# Создать топик с 3 партициями
kafka-topics --create \
--topic my-topic \
--bootstrap-server localhost:9092 \
--partitions 3 \
--replication-factor 1

# === Удаление ===
kafka-topics --delete --topic my-topic --bootstrap-server localhost:9092

# === Изменение ===
# Увеличить количество партиций до 5
kafka-topics --alter \
--topic my-topic \
--bootstrap-server localhost:9092 \
--partitions 5
3️⃣ Работа с сообщениями (Producer & Consumer)
bash
# === Producer (отправка сообщений) ===
# Интерактивный режим (пишем сообщения построчно)
kafka-console-producer --topic my-topic --bootstrap-server localhost:9092

# Отправить одно сообщение
echo "Hello Kafka" | kafka-console-producer \
--topic my-topic \
--bootstrap-server localhost:9092


echo "Hello Kafka" | kafka-console-producer \
--topic orders \
--bootstrap-server localhost:9092

# С ключами (key-value)
kafka-console-producer \
--topic my-topic \
--bootstrap-server localhost:9092 \
--property parse.key=true \
--property key.separator=:

# === Consumer (чтение сообщений) ===
# Читать все сообщения с начала
kafka-console-consumer \
--topic my-topic \
--bootstrap-server localhost:9092 \
--from-beginning

# Читать только новые сообщения (начиная с текущего момента)
kafka-console-consumer \
--topic my-topic \
--bootstrap-server localhost:9092

kafka-console-consumer \
--topic orders \
--bootstrap-server localhost:9092

# Читать последние N сообщений
kafka-console-consumer \
--topic my-topic \
--bootstrap-server localhost:9092 \
--max-messages 10

# Читать с указанием партиции
kafka-console-consumer \
--topic my-topic \
--bootstrap-server localhost:9092 \
--partition 0 \
--offset earliest
4️⃣ Управление Consumer Groups
bash
# === Просмотр групп ===
# Список всех consumer групп
kafka-consumer-groups --list --bootstrap-server localhost:9092

# Детальная информация о группе
kafka-consumer-groups --describe \
--group my-group \
--bootstrap-server localhost:9092

# === Управление ===
# Сбросить смещения (offset) до начала
kafka-consumer-groups --reset-offsets \
--group my-group \
--topic my-topic \
--to-earliest \
--bootstrap-server localhost:9092 \
--execute

# Сбросить до определенного смещения
kafka-consumer-groups --reset-offsets \
--group my-group \
--topic my-topic:0 \
--to-offset 100 \
--bootstrap-server localhost:9092 \
--execute

# Удалить группу
kafka-consumer-groups --delete \
--group my-group \
--bootstrap-server localhost:9092
5️⃣ Мониторинг и диагностика
bash
# === Информация о брокере ===
# Версия Kafka
kafka-broker-api-versions --bootstrap-server localhost:9092

# Метрики брокера
kafka-run-class kafka.tools.JmxTool --help

# === Размер топиков ===
# Показать размер всех топиков
kafka-log-dirs --describe \
--bootstrap-server localhost:9092 \
--broker-list 1

# === Проверка конфигурации ===
# Показать конфигурацию брокера
kafka-configs --describe \
--bootstrap-server localhost:9092 \
--entity-type brokers \
--entity-default

# Конфигурация топика
kafka-configs --describe \
--bootstrap-server localhost:9092 \
--entity-type topics \
--entity-name my-topic
6️⃣ Работа с партициями и репликами
bash
# === Просмотр оффсетов ===
# Минимальный оффсет (самое раннее сообщение)
kafka-run-class kafka.tools.GetOffsetShell \
--topic my-topic \
--time -2 \
--bootstrap-server localhost:9092

# Максимальный оффсет (последнее сообщение)
kafka-run-class kafka.tools.GetOffsetShell \
--topic my-topic \
--time -1 \
--bootstrap-server localhost:9092

# === Распределение реплик ===
kafka-topics --describe \
--topic my-topic \
--bootstrap-server localhost:9092
7️⃣ Dump логов (для отладки)
bash
# Просмотр содержимого логов Kafka (сегментов)
kafka-dump-log --files /var/lib/kafka/data/my-topic-0/00000000000000000000.log

# С информацией о смещениях
kafka-dump-log \
--files /var/lib/kafka/data/my-topic-0/00000000000000000000.log \
--print-data-log
8️⃣ Практические примеры
Пример 1: Полный цикл работы с топиком
bash
# 1. Создать топик
kafka-topics --create \
--topic orders \
--bootstrap-server localhost:9092 \
--partitions 3 \
--replication-factor 1

# 2. Проверить создание
kafka-topics --list --bootstrap-server localhost:9092

# 3. Отправить сообщения
echo "Order #1: 100$" | kafka-console-producer --topic orders --bootstrap-server localhost:9092
echo "Order #2: 250$" | kafka-console-producer --topic orders --bootstrap-server localhost:9092
echo "Order #3: 75$"  | kafka-console-producer --topic orders --bootstrap-server localhost:9092

# 4. Прочитать сообщения
kafka-console-consumer --topic orders --bootstrap-server localhost:9092 --from-beginning
Пример 2: Мониторинг consumer lag (отставание)
bash
# Создаем consumer группу
kafka-console-consumer --topic orders --group my-group --bootstrap-server localhost:9092 &

# Смотрим lag
kafka-consumer-groups --describe --group my-group --bootstrap-server localhost:9092

# Результат:
# GROUP      TOPIC  PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# my-group   orders 0          10              15              5
Пример 3: Работа с ключами сообщений
bash
# Отправка с ключами
kafka-console-producer \
--topic users \
--bootstrap-server localhost:9092 \
--property parse.key=true \
--property key.separator=:

# Вводим:
user1:{"name":"Alice","age":30}
user2:{"name":"Bob","age":25}
user1:{"name":"Alice","age":31}

# Чтение с ключами
kafka-console-consumer \
--topic users \
--bootstrap-server localhost:9092 \
--from-beginning \
--property print.key=true \
--property key.separator=" - "
Пример 4: Партиционирование
bash
# Создать топик с ключевой партицией
kafka-topics --create \
--topic partitioned \
--bootstrap-server localhost:9092 \
--partitions 5 \
--replication-factor 1

# Отправить в конкретную партицию
echo "Message to partition 2" | kafka-console-producer \
--topic partitioned \
--bootstrap-server localhost:9092 \
--partition 2

# Читать из конкретной партиции
kafka-console-consumer \
--topic partitioned \
--bootstrap-server localhost:9092 \
--partition 2 \
--from-beginning
9️⃣ Полезные однострочники
bash
# Создать топик и сразу отправить в него сообщение
kafka-topics --create --topic quick --bootstrap-server localhost:9092 --partitions 1 && \
echo "Quick message" | kafka-console-producer --topic quick --bootstrap-server localhost:9092

# Копировать сообщения из одного топика в другой
kafka-console-consumer --topic source --bootstrap-server localhost:9092 --from-beginning | \
kafka-console-producer --topic target --bootstrap-server localhost:9092

# Подсчитать количество сообщений в топике
kafka-run-class kafka.tools.GetOffsetShell \
--topic my-topic \
--bootstrap-server localhost:9092 \
| awk -F ":" '{sum += $3} END {print sum}'

# Удалить все топики начинающиеся с "test-"
for topic in $(kafka-topics --list --bootstrap-server localhost:9092 | grep "^test-"); do
kafka-topics --delete --topic $topic --bootstrap-server localhost:9092
done
🔟 Проверка работоспособности
bash
# Быстрая проверка что Kafka работает
kafka-broker-api-versions --bootstrap-server localhost:9092 2>&1 | grep -q "Valid" && echo "✅ Kafka OK" || echo "❌ Kafka ERROR"

# Проверка создания топика
kafka-topics --list --bootstrap-server localhost:9092 | grep -q "my-topic" && echo "✅ Topic exists" || echo "❌ Topic missing"

# Проверка отправки сообщения
echo "test" | kafka-console-producer --topic test-check --bootstrap-server localhost:9092 2>/dev/null && echo "✅ Producer OK"
🚀 Быстрый старт для тестирования
bash
# 1. Войти в Kafka
docker exec -it myapp-kafka bash

# 2. Создать тестовый топик
kafka-topics --create --topic test --bootstrap-server localhost:9092

# 3. Запустить продюсера (в одном окне)
kafka-console-producer --topic test --bootstrap-server localhost:9092

# 4. Запустить консюмера (в другом окне)
kafka-console-consumer --topic test --bootstrap-server localhost:9092 --from-beginning

# 5. Мониторить группы
kafka-consumer-groups --list --bootstrap-server localhost:9092