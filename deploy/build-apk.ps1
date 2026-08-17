param(
    [string]$ApiBaseUrl = "https://empregos.apelmat.com.br/api"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$appDirectory = Join-Path $projectRoot "app"

if (-not $ApiBaseUrl.EndsWith("/api")) {
    throw "A URL precisa terminar com /api. Exemplo: https://api.apelmat.com.br/api"
}

Push-Location $appDirectory
try {
    flutter pub get
    flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"
} finally {
    Pop-Location
}

Write-Host "APK criado em app/build/app/outputs/flutter-apk/app-release.apk"
