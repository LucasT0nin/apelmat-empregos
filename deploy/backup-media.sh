#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env.vps ]; then
    echo "Arquivo deploy/.env.vps nao encontrado."
    exit 1
fi

mkdir -p backups
timestamp="$(date +%Y%m%d-%H%M%S)"

docker compose --env-file .env.vps -f compose.vps.yml run \
    --rm --no-deps \
    -v "$(pwd)/backups:/backup" \
    backend python -c \
    "import shutil; shutil.make_archive('/backup/apelmat-media-$timestamp', 'gztar', '/app/media')"

echo "Backup de curriculos criado em backups/apelmat-media-$timestamp.tar.gz"
