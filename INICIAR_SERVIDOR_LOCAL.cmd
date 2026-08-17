@echo off
cd /d "%~dp0"
echo.
echo Ligando Apelmat Empregos na rede local...
echo API do app: http://192.168.0.67:8000/api
echo Teste no navegador do PC: http://127.0.0.1:8000/api/health/
echo Teste no celular: http://192.168.0.67:8000/api/health/
echo.
.\.venv\Scripts\python.exe backend\manage.py migrate
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
pause
