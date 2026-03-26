#FROM openjdk:17-jdk-slim
FROM eclipse-temurin:17-jdk-jammy

LABEL authors="Vasman"

WORKDIR /app

# Установка переменной окружения по умолчанию
#ENV SPRING_PROFILES_ACTIVE=dev

# Копируем JAR файл
COPY target/practice-1.0-SNAPSHOT.jar app.jar

# Порт приложения
EXPOSE 8095

# Запускаем приложение с возможностью переопределения профиля
ENTRYPOINT ["java", "-jar", "app.jar"]