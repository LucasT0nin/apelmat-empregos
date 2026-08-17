$ErrorActionPreference = "Stop"

$repo = $PSScriptRoot
$app = Join-Path $repo "app"
$outputs = Join-Path $repo "outputs"
$localSdk = Join-Path $repo ".tool-home\android-sdk-local"
$apiBaseUrl = "http://192.168.0.67:8000/api"

New-Item -ItemType Directory -Force $outputs | Out-Null
New-Item -ItemType Directory -Force (Join-Path $localSdk "platforms") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $localSdk "build-tools") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $localSdk "platform-tools") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $localSdk "ndk\27.0.12077973") | Out-Null

$androidSdk = $env:ANDROID_HOME
if (-not $androidSdk -or -not (Test-Path $androidSdk)) {
    $androidSdk = Join-Path $env:LOCALAPPDATA "Android\sdk"
}
if (-not (Test-Path $androidSdk)) {
    throw "Android SDK nao encontrado. Abra o Android Studio uma vez ou configure ANDROID_HOME."
}

$platformSource = Join-Path $androidSdk "platforms\android-35"
if (-not (Test-Path (Join-Path $platformSource "android.jar"))) {
    throw "Android platform 35 nao encontrado em $platformSource. Instale Android SDK Platform 35 no Android Studio."
}
$platformTarget = Join-Path $localSdk "platforms\android-35"
if (-not (Test-Path $platformTarget)) {
    New-Item -ItemType Junction -Path $platformTarget -Target $platformSource | Out-Null
}

$buildToolsSource = Join-Path $androidSdk "build-tools\34.0.0"
if (-not (Test-Path (Join-Path $buildToolsSource "aapt2.exe"))) {
    throw "Android build-tools 34.0.0 nao encontrado. Instale pelo Android Studio."
}
$buildToolsTarget = Join-Path $localSdk "build-tools\35.0.0"
if (-not (Test-Path $buildToolsTarget)) {
    New-Item -ItemType Junction -Path $buildToolsTarget -Target $buildToolsSource | Out-Null
}

$ndkSourceProperties = @"
Pkg.Desc = Android NDK
Pkg.Revision = 27.0.12077973
Pkg.Path = ndk;27.0.12077973
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $localSdk "ndk\27.0.12077973\source.properties"), $ndkSourceProperties, $utf8NoBom)

$flutterCommand = (Get-Command flutter -ErrorAction Stop).Source
$flutterSdk = Split-Path (Split-Path $flutterCommand -Parent) -Parent

$localProperties = @"
sdk.dir=$($localSdk.Replace('\', '\\'))
flutter.sdk=$($flutterSdk.Replace('\', '\\'))
flutter.buildMode=debug
flutter.versionName=1.4.3
flutter.versionCode=8
"@
[System.IO.File]::WriteAllText((Join-Path $app "android\local.properties"), $localProperties, $utf8NoBom)

Push-Location $app
try {
    flutter pub get
}
finally {
    Pop-Location
}

$dartDefine = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("API_BASE_URL=$apiBaseUrl"))

Push-Location (Join-Path $app "android")
try {
    .\gradlew.bat --no-daemon "-Ptarget-platform=android-arm,android-arm64,android-x64" "-Pdart-defines=$dartDefine" app:assembleDebug
}
finally {
    Pop-Location
}

$sourceApk = Join-Path $app "build\app\outputs\apk\debug\app-debug.apk"
if (-not (Test-Path $sourceApk)) {
    $sourceApk = Join-Path $app "build\app\outputs\flutter-apk\app-debug.apk"
}
if (-not (Test-Path $sourceApk)) {
    throw "APK nao encontrado depois do build."
}

$destApk = Join-Path $outputs "APELMAT-EMPREGOS-TESTE-LOCAL-v1.4.3-192.168.0.67.apk"
Copy-Item -LiteralPath $sourceApk -Destination $destApk -Force

Write-Host ""
Write-Host "APK gerado com sucesso:"
Write-Host $destApk
