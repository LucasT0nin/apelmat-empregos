# Pacote completo Apelmat Empregos

## Conteudo

- `app/`: codigo completo do aplicativo Flutter para Android e iOS;
- `backend/`: servidor Django, API, painel administrativo e migrations;
- `deploy/`: MySQL, HTTPS automatico, Gunicorn e scripts para a VPS;
- `database/`: explicacao do banco MySQL oficial e persistente;
- `apk/`: APK oficial conectado a `empregos.apelmat.com.br`;
- `docs/`: arquitetura, escopo e guias complementares.

## Por onde comecar

- Para abrir no VS Code, abra a pasta inteira deste pacote.
- Para executar no Windows, siga `docs/setup-windows.md`.
- Para instalar na VPS Locaweb, siga `VPS-LOCAWEB.md`.
- Para entender a persistencia do banco, consulte `database/README.md`.

O APK oficial usa `https://empregos.apelmat.com.br/api`. Ele passa a acessar o
servidor assim que o DNS do dominio apontar para a VPS e os containers estiverem
ativos.
