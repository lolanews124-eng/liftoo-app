# Liftoo — Firebase / FlutterFire setup (run once after Firebase Console shows CLI steps)
# Usage: .\scripts\setup-firebase.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$flutterBin = "c:\Liftoo\.tools\flutter\bin"
$pubBin = "$env:LOCALAPPDATA\Pub\Cache\bin"

$env:Path = "$pubBin;$flutterBin;" + $env:Path

Write-Host "1/4 Checking Firebase CLI..." -ForegroundColor Cyan
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Installing firebase-tools (npm)..." -ForegroundColor Yellow
    npm install -g firebase-tools
}

Write-Host "2/4 Activating FlutterFire CLI..." -ForegroundColor Cyan
& "$flutterBin\dart.bat" pub global activate flutterfire_cli

Write-Host "3/4 Login to Firebase (browser will open)..." -ForegroundColor Cyan
firebase login

Push-Location $root
try {
    Write-Host "4/4 Configuring project liftoo-6672b..." -ForegroundColor Cyan
    flutterfire configure --project=liftoo-6672b --platforms=android,ios,web --yes
    & "$flutterBin\flutter.bat" pub get
    Write-Host ""
    Write-Host "Done. Files created:" -ForegroundColor Green
    Write-Host "  - lib/firebase_options.dart"
    Write-Host "  - android/app/google-services.json"
    Write-Host "  - ios/Runner/GoogleService-Info.plist"
    Write-Host ""
    Write-Host "Next: rebuild APK with flutter build apk --release"
} finally {
    Pop-Location
}
