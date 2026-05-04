# Перейдите в папку со скриптами
cd d:/PracticeJava/pract-core/scripts

# Дайте права на выполнение (для Git Bash)
chmod +x *.sh

# Только сборка
TAG=v1.0.0 ./ci-build.sh

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
TAG=v1.0.0 ./ci-build.sh

# Собрать и отправить в свой registry
REGISTRY=myregistry.com/ ./ci-build.sh

-----------------------------------------------------------------------------
🔹 Только CD (деплой готовых образов)
bash
# Деплой в production последней версии
./cd-deploy.sh prod latest deploy

# Деплой конкретной версии в staging
./cd-deploy.sh staging v1.2.3 deploy

# Деплой в dev с хэшем коммита
./cd-deploy.sh dev abc1234 deploy

# Откат в production к предыдущей версии
./cd-deploy.sh prod v1.2.2 rollback

# Проверить статус
./cd-deploy.sh prod latest status

-----------------------------------------------------------------------------
🔹 Полный CI/CD одной командой
bash
# Полный цикл: сборка → публикация → деплой
./cicd.sh full prod v1.2.3

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