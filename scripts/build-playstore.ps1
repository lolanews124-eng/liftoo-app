# Builds a Play Store-ready Android App Bundle (AAB) with signing + obfuscation.
# Usage:
#   .\scripts\build-playstore.ps1
#   .\scripts\build-playstore.ps1 -BumpVersion
#
# Prerequisites:
#   .\scripts\setup-playstore-keystore.ps1   (one-time)
#   API URL in lib/core/config/app_config.dart (https://api.liftoo.in)

param(
    [switch]$BumpVersion,
    [switch]$SkipPubGet
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$keyProps = Join-Path $root "android\key.properties"
$keystore = Join-Path $root "android\app\liftoo-upload-keystore.jks"
$pubspec = Join-Path $root "pubspec.yaml"

function Ensure-FlutterInPath {
    if (Get-Command flutter -ErrorAction SilentlyContinue) { return }
    $bundled = "c:\Liftoo\.tools\flutter\bin"
    if (Test-Path (Join-Path $bundled "flutter.bat")) {
        $env:Path = "$bundled;" + $env:Path
        return
    }
    throw "flutter not found in PATH. Install Flutter or add .tools/flutter/bin to PATH."
}

if (-not (Test-Path $keyProps)) {
    Write-Error "Missing android/key.properties. Run scripts/setup-playstore-keystore.ps1"
}
if (-not (Test-Path $keystore)) {
    Write-Error "Missing android/app/liftoo-upload-keystore.jks. Run scripts/setup-playstore-keystore.ps1"
}

if ($BumpVersion) {
    $content = Get-Content $pubspec -Raw
    if ($content -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        $name = $Matches[1]
        $code = [int]$Matches[2] + 1
        $newVersion = "version: $name+$code"
        $content = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newVersion
        Set-Content $pubspec $content -NoNewline
        Write-Host "Bumped version to $name+$code" -ForegroundColor Yellow
    }
}

Ensure-FlutterInPath

Push-Location $root
try {
    $versionLine = (Select-String -Path $pubspec -Pattern '^version:' | Select-Object -First 1).Line.Trim()
    Write-Host "Building Play Store bundle ($versionLine)..." -ForegroundColor Cyan

    if (-not $SkipPubGet) {
        flutter pub get
    }

    flutter build appbundle --release `
        --obfuscate `
        --split-debug-info=build/app/outputs/symbols

    $aab = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path $aab)) {
        Write-Error "AAB not found after build."
    }

    $dest = Join-Path (Split-Path -Parent $root) "Liftoo-playstore-release.aab"
    Copy-Item $aab $dest -Force

    $sizeMb = "{0:N1} MB" -f ((Get-Item $dest).Length / 1MB)
    Write-Host ""
    Write-Host "Play Store bundle ready: $sizeMb" -ForegroundColor Green
    Write-Host $dest
    Write-Host ""
    Write-Host "Next: Play Console, Testing, Internal testing, Create release"
    Write-Host "Symbols: build/app/outputs/symbols/"
} finally {
    Pop-Location
}
