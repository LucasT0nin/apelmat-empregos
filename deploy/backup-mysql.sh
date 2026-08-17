#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env.vps ]; then
    echo "Arquivo deploy/.env.vps nao encontrado."
    exit 1
fi

mkdir -p backups
backup_file="backups/apelmat-$(date +%Y%m%d-%H%M%S).sql.gz"

docker compose --env-file .env.vps -f compose.vps.yml exec -T db \
    sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --triggers "$MYSQL_DATABASE"' \
    | gzip > "$backup_file"

echo "Backup criado em: $backup_file"
