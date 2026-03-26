#FROM openjdk:17-jdk-slim
#LABEL authors="Vasman"
#WORKDIR /app
#
## Копируем скрипт запуска
#COPY start-app.sh /app/
#RUN chmod +x /app/start-app.sh
#
## Создаем пустой jar для начальной работы (если нужно)
#RUN touch /app/app.jar
#
## Указываем скрипт как точку входа
#ENTRYPOINT ["/app/start-app.sh"]



FROM openjdk:17-jdk-slim
LABEL authors="Vasman"
WORKDIR /app

# Установка переменной окружения по умолчанию
#ENV SPRING_PROFILES_ACTIVE=dev

# Копируем скрипт запуска
COPY start-app.sh /app/
RUN chmod +x /app/start-app.sh

# Копируем JAR-файл при сборке (начальная версия)
ARG JAR_FILE=target/practice-*.jar
COPY ${JAR_FILE} /app/app.jar

# Указываем скрипт как точку входа
ENTRYPOINT ["/app/start-app.sh"]


#FROM openjdk:17-alpine
##FROM openjdk:17-jdk-slim
#LABEL authors="Vasman"
#WORKDIR /app
#COPY start-app.sh .
#RUN chmod +x start-app.sh
#CMD ["./start-app.sh"]


#Старый рабочий dockerfile
#FROM openjdk:17-jdk-slim
#LABEL authors="Vasman"
## Указываем рабочую директорию внутри контейнера
#WORKDIR /app
## Копируем JAR-файл приложения в контейнер
## Для Maven: target/*.jar
## Для Gradle: build/libs/*.jar
#ARG JAR_FILE=target/practice-*.jar
#COPY ${JAR_FILE} app.jar
#
#VOLUME /app
## Команда для запуска приложения
#ENTRYPOINT ["java", "-jar", "/app/app.jar"]
