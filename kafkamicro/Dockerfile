FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Копируем JAR файл (убедитесь, что имя совпадает)
COPY target/kafkamicro-1.0-SNAPSHOT.jar app.jar

# Порт приложения
EXPOSE 8097

ENTRYPOINT ["java", "-jar", "app.jar"]