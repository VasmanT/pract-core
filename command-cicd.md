# Перейдите в папку со скриптами
cd d:/PracticeJava/pract-core/scripts

# Дайте права на выполнение (для Git Bash)
chmod +x *.sh

# Только сборка
TAG=v18.0.0 ./ci-build.sh

# Только деплой
./cd-deploy.sh dev latest deploy

# Полный CI/CD
./cicd.sh full dev v1.0.0

# Статус
./cicd.sh status dev

# Помощь
./cicd.sh help

-------------------------------
Команды для использования

🔹 Локальная разработка (быстрый старт)
bash
# Просто запустить всё из исходников (без registry)
docker compose up -d --build
-----------------------------------------------------------------------------
🔹 Только CI (сборка образов)
bash
# Собрать образы с тегом = хэш коммита
./ci-build.sh

# Собрать с конкретным тегом
TAG=v27.1.1 ./ci-build.sh

# Собрать и отправить в свой registry
REGISTRY=myregistry.com/ ./ci-build.sh

-----------------------------------------------------------------------------
🔹 Только CD (деплой готовых образов)
bash
# Деплой в production последней версии
./cd-deploy.sh prod latest deploy

# Деплой конкретной версии в staging
./cd-deploy.sh staging v26.1.1 deploy

# Деплой в dev с хэшем коммита
./cd-deploy.sh dev abc1234 deploy

# Откат в production к предыдущей версии
./cd-deploy.sh prod v26.1.1 rollback

# Проверить статус
./cd-deploy.sh prod latest status

-----------------------------------------------------------------------------
🔹 Полный CI/CD одной командой
bash
# Полный цикл: сборка → публикация → деплой
./cicd.sh full prod v26.1.1

# Только сборка
./cicd.sh build-only

# Только деплой последней версии в staging
./cicd.sh deploy-only staging latest

# Откат
./cicd.sh rollback prod v1.2.2

# Статус
./cicd.sh status prod

-----------------------------------------------------------------------------
4️⃣ Типичные сценарии использования

Сценарий А: Разработчик делает релиз
bash
git tag v1.0.0
git push origin v1.0.0
./cicd.sh full prod v1.0.0

-----------------------------------------------------------------------------
Сценарий Б: Деплой без пересборки
bash
# Уже есть образ в registry
./cicd.sh deploy-only staging v1.0.0

-----------------------------------------------------------------------------
Сценарий В: Только пересобрать образы
bash
# Пересобрали код, нужно обновить образы, но не деплоить
./cicd.sh build-only

-----------------------------------------------------------------------------
Сценарий Г: Откат проблемного релиза
bash
./cicd.sh rollback prod v0.9.9

-----------------------------------------------------------------------------
5️⃣ Важные замечания
Для работы без registry (локально):

bash
REGISTRY="" ./cicd.sh full dev
Для работы с registry:

bash
export REGISTRY="myregistry.com/"
docker login myregistry.com
./cicd.sh full prod v1.0.0


Healthcheck требует наличия actuator в Spring Boot приложениях

Порт БД: внешний 5436, внутренний 5432

--------------------------------------------------------------------------------
cd d:/PracticeJava/pract-core/dbmicro
$ mvn clean package -DskipTests
$ docker build -t myapp-dbmicro:v30.1.3 .
$ docker run -d -p 8096:8096 -e "SPRING_PROFILES_ACTIVE=prod" myapp-dbmicro:v30.1.3

---
cd d:/PracticeJava/pract-core/practice
$ mvn clean package -DskipTests
$ docker build -t myapp-practice:v30.1.3 .
$ docker run -d -p 8095:8095 -e "SPRING_PROFILES_ACTIVE=prod" myapp-practice:v30.1.3

---
cd d:/PracticeJava/pract-core/kafkamicro
$ mvn clean package -DskipTests
$ docker build -t myapp-kafka-micro:v30.1.3 .
$ docker run -d -p 8097:8097 -e "SPRING_PROFILES_ACTIVE=prod" myapp-kafka-micro:v30.1.3