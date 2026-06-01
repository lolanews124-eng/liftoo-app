# Builds a Play Store-ready Android App Bundle (AAB) with signing + obfuscation.
# Usage:
#   .\scripts\build-playstore.ps1
#   .\scripts\build-playstore.ps1 -ApiUrl "https://api.yourdomain.com"

param(
    [string]$ApiUrl = "https://api.liftoo.in"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$keyProps = Join-Path $root "android\key.properties"

if (-not (Test-Path $keyProps)) {
    Write-Error "Missing android/key.properties. Run keystore setup first (see PLAYSTORE.md)."
}

Push-Location $root
try {
    flutter pub get
    flutter build appbundle --release `
        --obfuscate `
        --split-debug-info=build/app/outputs/symbols `
        --dart-define=API_BASE_URL=$ApiUrl `
        --dart-define=SOCKET_URL=$ApiUrl

    $aab = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aab) {
        $dest = Join-Path (Split-Path -Parent $root) "Liftoo-playstore-release.aab"
        Copy-Item $aab $dest -Force
        Write-Host ""
        Write-Host "Play Store bundle ready:" -ForegroundColor Green
        Write-Host $dest
        Write-Host "Upload this file to Google Play Console."
    }
} finally {
    Pop-Location
}
