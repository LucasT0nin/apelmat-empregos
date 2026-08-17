# Apelmat Empregos

Aplicativo mobile e backend para catalogo controlado de profissionais. O
profissional cadastra curriculo e ate 3 areas de trabalho; empresas consultam o
catalogo e solicitam contato; a Apelmat aprova manualmente no painel
administrativo antes de liberar WhatsApp, e-mail ou PDF.

## Tecnologias

- Flutter para Android e iOS
- Django 5.2 LTS e Django REST Framework
- SQLite para desenvolvimento local
- MySQL 8.4 no pacote de producao para VPS
- Docker Compose, Caddy e Gunicorn na VPS
- Notificacoes internas por polling no aplicativo

## Estrutura

```text
app/          Aplicativo Flutter
backend/      API, regras de negocio e painel administrativo
docs/         Decisoes de produto e arquitetura
deploy/       Docker, HTTPS automatico, MySQL, backup e scripts para a VPS
database/     Guia do banco oficial MySQL
outputs/      APKs, zips e guias de entrega/teste
```

## Fluxo oficial

- Profissional: cria conta, preenche curriculo, envia PDF opcional, escolhe ate
  3 areas entre operador, motorista de caminhao, encarregado e engenheiro.
- Apelmat: analisa curriculo e areas no Django Admin, publica no catalogo e pode
  aplicar o selo "verificado pela Apelmat".
- Empresa: consulta o catalogo, pesquisa profissionais e clica em
  `Solicitar contato`.
- Apelmat: recebe a solicitacao no painel e decide liberar ou recusar.
- Contato: somente depois da aprovacao a empresa ve WhatsApp, e-mail e PDF.

## O que ja funciona

- Cadastro e login com JWT.
- Perfil de profissional e empresa.
- Curriculo base com PDF opcional e status de analise/publicacao.
- Cadastro de ate 3 areas profissionais com perguntas especificas.
- Catalogo de profissionais publicado somente apos aprovacao.
- Selo `verificado pela Apelmat`.
- Solicitar contato com um clique pela empresa.
- Painel administrativo para aprovar curriculos, areas e contatos.
- WhatsApp/e-mail/PDF ocultos ate a liberacao.
- Avisos internos para analise, solicitacao e contato liberado.
- Denuncias, bloqueios e exclusao de conta no backend.
- Paginas publicas de Termos de Uso e Privacidade.
- Documentacao OpenAPI.
- Aplicativo Android compilavel.
- Identidade visual clean em branco e dourado com icone oficial Apelmat.

## Executar localmente

No Windows, siga o guia em `docs/setup-windows.md`.

Backend local:

```powershell
.\.venv\Scripts\python.exe backend\manage.py migrate
.\.venv\Scripts\python.exe backend\manage.py seed_demo
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000
```

App no emulador:

```powershell
cd app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

App no celular fisico:

```powershell
cd app
flutter run --dart-define=API_BASE_URL=http://SEU-IP:8000/api
```

## Instalar na VPS Locaweb

O pacote de producao fica em `deploy/` e sobe Caddy, Django/Gunicorn e MySQL
com volumes persistentes. Siga o passo a passo em `VPS-LOCAWEB.md`.

## Principios

- A Apelmat controla a liberacao de contatos.
- Dados privados nao aparecem no catalogo sem aprovacao.
- PDF e anexo opcional; o curriculo estruturado fica no banco.
- A plataforma aproxima as partes, mas nao faz pagamento, contrato ou selecao
  final.
- Toda regra importante tambem e validada no backend.
