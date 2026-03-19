# Остановите и удалите старый контейнер
docker stop youthful_swirles
docker rm youthful_swirles

# Создайте новый контейнер с правильным именем
docker run -d \
    --name myapp-practice \
    -p 8095:8095 \
    -v /app \
    --restart unless-stopped \
    myapp-practice:latest \
    tail -f /dev/null

# Создайте директорию app
docker exec myapp-practice mkdir -p /app