# Onde configurar o banco MySQL da Locaweb

## Nao envie este ZIP para o phpMyAdmin

O MySQL nao executa o aplicativo e nao recebe o codigo Flutter ou Django. No
painel da Locaweb, crie apenas um banco MySQL vazio e anote:

- host do banco;
- porta, normalmente 3306;
- nome do banco;
- usuario;
- senha.

## Onde colocar esses dados

Na VPS, dentro da pasta `deploy` do pacote 1:

```bash
cp .env.vps-external.example .env.vps-external
nano .env.vps-external
```

Preencha as cinco variaveis `MYSQL_*`. Depois execute:

```bash
chmod +x start-vps-external-mysql.sh
./start-vps-external-mysql.sh
```

O comando `python manage.py migrate` executado pelo container cria todas as
tabelas oficiais no banco vazio. Nao existe SQL de dados ficticios para
importar. As migrations incluidas neste pacote sao a versao oficial da
estrutura do banco.

## Opcao mais simples

Se voce nao contratou um banco MySQL separado na Locaweb, nao use o pacote 2.
O pacote 1 ja inicia um MySQL privado dentro da propria VPS e cria tudo
automaticamente com `./start-vps.sh`.
