param(
    [string]$ApiBaseUrl = "https://empregos.apelmat.com.br/api"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$appDirectory = Join-Path $projectRoot "app"

if (-not $ApiBaseUrl.EndsWith("/api")) {
    throw "A URL precisa terminar com /api. Exemplo: https://empregos.apelmat.com.br/api"
}

Push-Location $appDirectory
try {
    flutter pub get
    flutter build appbundle --release --dart-define="API_BASE_URL=$ApiBaseUrl"
} finally {
    Pop-Location
}

Write-Host "AAB criado em app/build/app/outputs/bundle/release/app-release.aab"
