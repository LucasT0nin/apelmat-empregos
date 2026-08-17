# Instalacao na VPS Locaweb

Este pacote usa Docker Compose para executar:

- Caddy nas portas 80 e 443, com HTTPS automatico;
- Django com Gunicorn;
- MySQL 8.4;
- volumes persistentes para banco, curriculos e arquivos estaticos.

Ele exige uma VPS Linux com acesso SSH. Hospedagem compartilhada de sites nao
oferece o controle necessario para executar estes containers.

## 1. Preparar a VPS

Entre por SSH e instale Docker, Docker Compose e unzip. Em Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2 unzip
sudo systemctl enable --now docker
docker compose version
```

No painel da VPS, mantenha as portas 22, 80 e 443 liberadas. Restrinja a porta
22 ao seu IP quando possivel.

## 2. Apontar o dominio

No DNS de `apelmat.com.br`, crie um registro `A` com o nome `servicos` apontando
para o IP publico da VPS. O HTTPS so pode ser emitido depois que esse registro
estiver respondendo corretamente.

## 3. Enviar e descompactar

Envie o ZIP para a VPS, por exemplo para `/opt`, e execute:

```bash
cd /opt
sudo unzip apelmat-empregos-oficial-vps.zip -d apelmat-empregos
sudo chown -R "$USER":"$USER" apelmat-empregos
cd apelmat-empregos/deploy
```

## 4. Criar as senhas

```bash
cp .env.vps.example .env.vps
openssl rand -hex 48
openssl rand -hex 24
openssl rand -hex 24
nano .env.vps
```

Use o primeiro resultado em `DJANGO_SECRET_KEY` e os outros dois nas senhas do
MySQL. O dominio oficial ja esta preenchido. Nao envie `.env.vps` para outras
pessoas.

## 5. Iniciar o sistema

```bash
chmod +x start-vps.sh backup-mysql.sh restore-mysql.sh backup-media.sh restore-media.sh
./start-vps.sh
```

Teste no navegador:

```text
https://empregos.apelmat.com.br/api/health/
https://empregos.apelmat.com.br/admin/
https://empregos.apelmat.com.br/api/docs/
```

O endpoint de saude deve mostrar `{"status": "ok", "database": "ok"}`.

## 6. Criar o administrador

```bash
docker compose --env-file .env.vps -f compose.vps.yml exec backend python manage.py createsuperuser
```

## 7. Gerar o APK conectado a VPS

No Windows, dentro da pasta do projeto:

```powershell
.\deploy\build-apk.ps1
```

O script ja usa `https://empregos.apelmat.com.br/api`.

## Comandos uteis

Ver os servicos e logs:

```bash
docker compose --env-file .env.vps -f compose.vps.yml ps
docker compose --env-file .env.vps -f compose.vps.yml logs -f --tail=200
```

Atualizar depois de trocar o codigo:

```bash
./start-vps.sh
```

Criar um backup do MySQL:

```bash
./backup-mysql.sh
```

Criar um backup dos curriculos:

```bash
./backup-media.sh
```

Restaurar um backup:

```bash
./restore-mysql.sh backups/NOME-DO-ARQUIVO.sql.gz
```

Restaurar curriculos:

```bash
./restore-media.sh backups/apelmat-media-NOME-DO-ARQUIVO.tar.gz
```

Os curriculos ficam no volume Docker `apelmat-empregos_media_data`; inclua esse
volume na politica de backup da VPS alem do backup do MySQL.
