#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env.vps ]; then
    echo "Arquivo deploy/.env.vps nao encontrado."
    echo "Execute: cp .env.vps.example .env.vps"
    exit 1
fi

docker compose --env-file .env.vps -f compose.vps.yml up -d --build
docker compose --env-file .env.vps -f compose.vps.yml ps

echo "Apelmat iniciado. Teste: https://empregos.apelmat.com.br/api/health/"
