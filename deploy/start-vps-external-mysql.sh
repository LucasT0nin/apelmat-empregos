#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env.vps-external ]; then
    echo "Arquivo deploy/.env.vps-external nao encontrado."
    echo "Execute: cp .env.vps-external.example .env.vps-external"
    exit 1
fi

docker compose \
    --env-file .env.vps-external \
    -f compose.vps-external-mysql.yml \
    up -d --build

docker compose \
    --env-file .env.vps-external \
    -f compose.vps-external-mysql.yml \
    ps

echo "Servidor iniciado com o MySQL externo da Locaweb."
