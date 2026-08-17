@echo off
echo Abrindo permissao de Administrador para liberar a porta 8000...
echo Aceite a janela do Windows que vai aparecer.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command ""New-NetFirewallRule -DisplayName ''''Apelmat Empregos API Local 8000'''' -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Any; Write-Host ''''Porta 8000 liberada para o Apelmat Empregos.''''; Read-Host ''''Pressione ENTER para fechar''''""'"
