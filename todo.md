27.04.
Найти где на диске хранятся docker image и container
Именнованный docker image + версия. Как сделать. Чтобы не плодить имаджи.
Добавить версии в имаджи
НАбор скриптов сборка/запуск/сборка+запуск
Maven создание image


docker image prune -f
docker system prune -a --volumes
wsl --shutdown
wsl --unregister docker-desktop-data

!

# 1. Очистка дискачерез ps, - После перезагрузки удаляем папку с данными Docker
Remove-Item -Recurse -Force "C:\Users\Vasman\AppData\Local\Docker\wsl\data\*"

bash перестал видеть docker , - перезагрузить ps
Проверь, запущен ли докер!


05.05.
 В консоли удалить image docker rmi <номер>
 Если таже версия при сборке image, - замена
 что будет(будет несколько новых имаджей или один будет перезаписываться)!?
 Ctrl+R
 Горячие клавиши для навигации курсора в терминале и прочие
 Ctrl+Shift+M
 REGISTRY
 1. В dc добавить сервис запускающий кафку
 2. Проверить работу кафки. 1 Продюссер отправляет,
 один читает коммандами из терминала без java
 3. Использовать графический интерфейс OffsetExplorer + плагин для IDEA


 kafka-micro принимает запрос(get) от practice,
 kafka-micro при запросе от practice идёт в кафку получает что есть в топике и возвращает



https://www.youtube.com/watch?v=hbseyn-CfXY&t=1332s
https://javarush.com/quests/lectures/ru.javarush.java.spring.lecture.level19.lecture09