# Banco oficial

O banco oficial do Apelmat Empregos e MySQL 8.4 e roda na VPS em um volume
persistente. Sua estrutura completa esta versionada nas migrations de
`backend/accounts`, `backend/marketplace` e `backend/moderation`.

Ao executar `deploy/start-vps.sh`, o servidor cria ou atualiza automaticamente
as tabelas. O banco comeca limpo e recebe dados reais pelo aplicativo e pelo
painel administrativo.

Os dados ficam no volume Docker `apelmat-empregos_mysql_data`. O comando abaixo
gera um backup SQL compactado:

```bash
cd deploy
./backup-mysql.sh
```

O comando `python manage.py seed_demo` existe apenas para testes de
desenvolvimento e nao e executado automaticamente na VPS.
