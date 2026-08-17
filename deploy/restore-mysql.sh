#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Uso: ./restore-mysql.sh backups/arquivo.sql.gz"
    exit 1
fi

printf "Isso substituira dados existentes. Digite RESTAURAR para continuar: "
read -r confirmation
if [ "$confirmation" != "RESTAURAR" ]; then
    echo "Restauracao cancelada."
    exit 1
fi

gzip -dc "$1" | docker compose --env-file .env.vps -f compose.vps.yml exec -T db \
    sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'

echo "Banco restaurado."
