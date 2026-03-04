#!/bin/bash

set -e

CONTAINER_ID="${1:-9ea}"
PROJECT_ROOT="$(cd .. && pwd)"
JAR_PATH="${PROJECT_ROOT}/target/practice-0.0.1-SNAPSHOT.jar"
PROFILE="${2:-prod}"
#PROFILE="${2:-dev}"

echo "=== Деплой приложения ==="

# Сборка
echo "1. Собираем проект..."
cd "$PROJECT_ROOT"
mvn clean package -DskipTests

# Проверка
if [ ! -f "$JAR_PATH" ]; then
    echo "Ошибка: JAR файл не найден: $JAR_PATH"
    exit 1
fi

# Остановка контейнера
echo "2. Останавливаем контейнер..."
docker stop "$CONTAINER_ID" 2>/dev/null || echo "Контейнер не был запущен"

# Копирование JAR
echo "3. Копируем JAR в контейнер..."
docker cp "$JAR_PATH" "${CONTAINER_ID}:/app/app.jar"

# Запуск контейнера если он не запущен
echo "4. Запускаем/перезапускаем контейнер..."
docker start "$CONTAINER_ID" 2>/dev/null || docker restart "$CONTAINER_ID"

# Ждем
sleep 2

# Запускаем приложение с профилем ВНУТРИ контейнера
echo "5. Запускаем приложение с профилем '$PROFILE'..."
docker exec -d "$CONTAINER_ID" sh -c "pkill -f 'java.*jar' 2>/dev/null || true; java -jar /app/app.jar --spring.profiles.active=$PROFILE"

echo "=== Готово! ==="
echo "Проверьте: docker logs $CONTAINER_ID"
echo "Или: curl http://localhost:8089/actuator/env | grep -A5 -B5 'profiles'"