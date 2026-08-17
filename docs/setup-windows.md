# Primeiros passos no Windows

## 1. Backend

Abra um terminal na raiz do projeto:

```powershell
.\.venv\Scripts\Activate.ps1
cd backend
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Enquanto esse terminal estiver aberto, a API estara em:

```text
http://localhost:8000/api/
```

Para criar acesso ao painel administrativo:

```powershell
python manage.py createsuperuser
```

Depois visite `http://localhost:8000/admin/`.

## 2. Aplicativo Android

Abra outro terminal na raiz:

```powershell
cd app
flutter devices
flutter run
```

O endereco `10.0.2.2` usado pelo app representa o computador quando ele esta
rodando no emulador Android.

## 3. Aparelho fisico

O celular e o computador devem estar na mesma rede. Descubra o IPv4 do
computador com:

```powershell
ipconfig
```

Depois execute, substituindo o endereco:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000/api
```

Em producao, a API deve usar dominio proprio e HTTPS.

## 4. Testes

Backend:

```powershell
cd backend
..\.venv\Scripts\python.exe manage.py test
```

Flutter:

```powershell
cd app
flutter analyze
flutter test
```

## 5. Dados de demonstracao

Para criar contas, curriculos publicados e areas profissionais de teste:

```powershell
cd backend
..\.venv\Scripts\python.exe manage.py seed_demo
```

Senha de todas as contas de demonstracao:

```text
Teste12345!
```

Contas:

- `profissional@apelmat.com`: profissional publicado no catalogo.
- `contratante@apelmat.com`: empresa para consultar catalogo e solicitar contato.
- `admin@apelmat.com`: administrador para acessar o painel no app e `/admin/`.
