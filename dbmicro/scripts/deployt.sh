#!/bin/bash

mvn clean package -DskipTests


## Начальный запуск (если jar существует)
#if curl -s -f --max-time 5 "http://localhost:8089/api/players/getdata" then
#    curl -s -f --max-time 5 "http://localhost:8089/api/players/getdata"
#else
#    echo curl -s -f --max-time 5 "http://localhost:8089/api/players/getdata"
#fi
#curl -s -f --max-time 5 "http://localhost:8089/api/info/profile" /dev/null;

#            if curl -s -f --max-time 5 "http://localhost:8089/api/info/profile"  &>  /dev/null; then
#                echo "Сервис отвечает на: http://localhost:8089/api/info/profile"
#                echo curl_success=true
#                curl_success=true
#                else
#                                    echo "Не удалось подтвердить профиль в командной строке"
#fi
#
#
#if [ "$curl_success" = true ]; then
#                echo "Сервис успешно запущен и отвечает на HTTP запросы"
#fi
#done
