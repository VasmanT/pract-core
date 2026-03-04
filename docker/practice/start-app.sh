#!/bin/sh
echo "========================================="
echo "Starting Practice Service"
echo "========================================="
echo "Current directory: $(pwd)"
echo "Java version: $(java -version 2>&1 | head -n1)"
echo "JAR file: /app/app.jar"
echo "JAR file exists: $(if [ -f /app/app.jar ]; then echo "YES"; else echo "NO"; fi)"
echo "JAR file size: $(ls -lh /app/app.jar | awk '{print $5}')"
echo "========================================="

# Функция для запуска приложения
start_application() {
    echo "Starting application with profile: ${SPRING_PROFILES_ACTIVE:-dev}"
    exec java -jar /app/app.jar \
#        --spring.profiles.active=${SPRING_PROFILES_ACTIVE:-dev} \
        --server.port=8095
}

# Запускаем приложение
start_application