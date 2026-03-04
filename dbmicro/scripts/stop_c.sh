#!/bin/bash

# Параметры
CONTAINER_ID="${1:-9ea}"

echo "2. Останавливаем контейнер $CONTAINER_ID..."
    if docker stop "$CONTAINER_ID" &> /dev/null; then
        echo  "Контейнер остановлен"
    else
        echo  "Контейнер уже остановлен или не найден"
    fi