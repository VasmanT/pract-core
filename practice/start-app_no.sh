#!/bin/bash



# Функция для остановки Java-процесса
stop_application() {
    echo "Остановка приложения..."
    # Более надежный способ найти и остановить процесс
    if [ ! -z "$APP_PID" ]; then
        kill -TERM "$APP_PID" 2>/dev/null && wait "$APP_PID" 2>/dev/null
    else
        pkill -f "java.*app.jar" || true
    fi
    sleep 2
}

# Функция для запуска приложения
start_application() {
    echo "Запуск приложения..."
    java -jar /app/app.jar &
    export APP_PID=$!
    echo "Приложение запущено с PID: $APP_PID"
}

# Определяем профиль (по умолчанию dev)
#PROFILE=${SPRING_PROFILE:-dev}

# Функция для запуска приложения
#start_application() {
#    echo "Запуск приложения с профилем: $PROFILE"
#    java -jar -Dspring.profiles.active=$PROFILE /app/app.jar &
#    export APP_PID=$!
#    echo "Приложение запущено с PID: $APP_PID и профилем: $PROFILE"
#}


# Начальный запуск (если jar существует)
if [ -f /app/app.jar ]; then
    start_application
else
    echo "Ожидание app.jar..."
fi

# Бесконечный цикл для проверки обновлений
while true; do
    if [ -f /app/app.jar.new ]; then
        echo "Обнаружена новая версия приложения..."
        stop_application

        # Создаем резервную копию и заменяем jar
        if [ -f /app/app.jar ]; then
            mv /app/app.jar /app/app.jar.backup
        fi

        mv /app/app.jar.new /app/app.jar
        echo "Приложение обновлено успешно"
        start_application
    fi
    sleep 3
done

##!/bin/bash
#
## Функция для остановки Java-процесса
#stop_application() {
#    echo "Остановка приложения..."
#    # Ищем процесс java, который запущен с app.jar и убиваем его
#    pkill -f "java.*app.jar" || true
#    sleep 2
#}
#
## Функция для запуска приложения
#start_application() {
#    echo "Запуск приложения..."
#    java -jar /app/app.jar &
#    PID=$!
#    echo "Приложение запущено с PID: $PID"
#}
#
## Начальный запуск
#start_application
#
## Бесконечный цикл для проверки обновлений
#while true; do
#    if [ -f /app/app.jar.new ]; then
#        echo "Обнаружена новая версия приложения..."
#        stop_application
#        # Заменяем старый jar на новый
#        mv /app/app.jar.new /app/app.jar
#        start_application
#        echo "Приложение обновлено успешно"
#    fi
#    sleep 5
#done


##!/bin/bash
## Скрипт для запуска приложения с возможностью перезагрузки
#while true; do
#  if [ -f /app/app.jar ]; then
#    echo "Запуск приложения..."
#    java -jar /app/app.jar
#    echo "Приложение остановлено. Перезапуск через 2 сек..."
#    sleep 2
#  else
#    echo "Файл app.jar не найден. Ожидание..."
#    sleep 5
#  fi
#done