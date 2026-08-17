#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Uso: ./restore-media.sh backups/apelmat-media-ARQUIVO.tar.gz"
    exit 1
fi

printf "Isso substituira arquivos com o mesmo nome. Digite RESTAURAR: "
read -r confirmation
if [ "$confirmation" != "RESTAURAR" ]; then
    echo "Restauracao cancelada."
    exit 1
fi

archive_name="$(basename "$1")"
docker compose --env-file .env.vps -f compose.vps.yml run \
    --rm --no-deps \
    -v "$(pwd)/backups:/backup:ro" \
    backend python -c \
    "import shutil; shutil.unpack_archive('/backup/$archive_name', '/app/media')"

echo "Arquivos restaurados."
