# Используем официальный поддерживаемый образ Eclipse Temurin
FROM eclipse-temurin:17-jdk-jammy
LABEL authors="Vasman"
WORKDIR /app

# Установка полезных утилит для диагностики
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Копируем скрипт запуска
COPY start-app.sh /app/
RUN chmod +x /app/start-app.sh

# Создаем пустой JAR для инициализации (будет заменен при деплое)
RUN touch /app/app.jar

# Пробрасываем порт
EXPOSE 8096

# Запускаем скрипт
ENTRYPOINT ["/app/start-app.sh"]