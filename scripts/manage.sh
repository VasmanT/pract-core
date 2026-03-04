#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "Управление контейнерами"
    echo ""
    echo "Использование: $0 [команда] [сервис]"
    echo ""
    echo "Команды:"
    echo "  logs [сервис]    - показать логи (сервис: practice, dbmicro, или all)"
    echo "  status           - показать статус всех контейнеров"
    echo "  restart [сервис] - перезапустить контейнер(ы)"
    echo "  stop [сервис]    - остановить контейнер(ы)"
    echo "  start [сервис]   - запустить контейнер(ы)"
    echo "  exec [сервис]    - войти в контейнер"
    echo "  help             - показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 logs practice     - логи practice"
    echo "  $0 logs all          - логи всех сервисов"
    echo "  $0 restart all       - перезапустить все"
}

case "$1" in
    logs)
        case "$2" in
            practice) docker logs -f myapp-practice ;;
            dbmicro)  docker logs -f myapp-dbmicro ;;
            all|"")   docker logs -f myapp-practice & docker logs -f myapp-dbmicro ;;
            *)        echo "Неизвестный сервис: $2" ;;
        esac
        ;;
    status)
        docker ps --filter "name=myapp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    restart)
        if [ "$2" = "all" ] || [ -z "$2" ]; then
            docker restart myapp-practice myapp-dbmicro
        else
            docker restart "myapp-$2"
        fi
        ;;
    stop)
        if [ "$2" = "all" ] || [ -z "$2" ]; then
            docker stop myapp-practice myapp-dbmicro
        else
            docker stop "myapp-$2"
        fi
        ;;
    start)
        if [ "$2" = "all" ] || [ -z "$2" ]; then
            docker start myapp-practice myapp-dbmicro
        else
            docker start "myapp-$2"
        fi
        ;;
    exec)
        if [ -n "$2" ]; then
            docker exec -it "myapp-$2" sh
        else
            echo "Укажите сервис: practice или dbmicro"
        fi
        ;;
    help|*)
        show_help
        ;;
esac