#FROM openjdk:17-jdk-slim
FROM eclipse-temurin:17-jdk-jammy

LABEL authors="Vasman"

WORKDIR /app

# Копируем JAR файл
COPY target/dbmicro-1.0-SNAPSHOT.jar app.jar

# Порт приложения
EXPOSE 8096

# Запускаем приложение с возможностью переопределения профиля
ENTRYPOINT ["java", "-jar", "app.jar"]

