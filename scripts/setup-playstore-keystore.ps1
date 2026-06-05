# One-time Play Store upload keystore setup.
# Creates android/app/liftoo-upload-keystore.jks and android/key.properties (gitignored).
#
# Usage:
#   .\scripts\setup-playstore-keystore.ps1
#   .\scripts\setup-playstore-keystore.ps1 -StorePassword "YourSecurePass" -KeyPassword "YourSecurePass"
#   .\scripts\setup-playstore-keystore.ps1 -Force   # regenerate (only if you have not published yet)

param(
    [string]$StorePassword,
    [string]$KeyPassword,
    [string]$KeyAlias = "liftoo-upload",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$androidDir = Join-Path $root "android"
$keystorePath = Join-Path $androidDir "app\liftoo-upload-keystore.jks"
$keyPropsPath = Join-Path $androidDir "key.properties"
$credsPath = Join-Path $androidDir "KEYSTORE_CREDENTIALS.local.txt"

function Find-Keytool {
    $javaHome = $env:JAVA_HOME
    if ($javaHome) {
        $candidate = Join-Path $javaHome "bin\keytool.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $androidStudioJbr = @(
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr\bin\keytool.exe"
    )
    foreach ($p in $androidStudioJbr) {
        if (Test-Path $p) { return $p }
    }
    throw "keytool not found. Install Android Studio or set JAVA_HOME."
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function New-RandomPassword([int]$Length = 24) {
    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%"
    -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

if ((Test-Path $keystorePath) -and -not $Force) {
    Write-Host "Upload keystore already exists:" -ForegroundColor Yellow
    Write-Host $keystorePath
    Write-Host "Run with -Force only if this app was NEVER published on Play Store."
    if (-not (Test-Path $keyPropsPath)) {
        Write-Host "key.properties is missing — recreate it manually from android/key.properties.example"
    }
    exit 0
}

if ($Force -and (Test-Path $keystorePath)) {
    Remove-Item $keystorePath -Force
}

if (-not $StorePassword) {
    $StorePassword = New-RandomPassword
}
if (-not $KeyPassword) {
    $KeyPassword = $StorePassword
}

$keytool = Find-Keytool
Write-Host "Creating upload keystore..." -ForegroundColor Cyan

$dname = "CN=Liftoo, OU=Mobile, O=Liftoo, L=Kolkata, ST=West Bengal, C=IN"
& $keytool -genkeypair -v `
    -storetype JKS `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias $KeyAlias `
    -keystore $keystorePath `
    -storepass $StorePassword `
    -keypass $KeyPassword `
    -dname $dname

$keyProps = @"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=app/liftoo-upload-keystore.jks
"@
Write-Utf8NoBom $keyPropsPath $keyProps

$creds = @"
Liftoo Upload Keystore — KEEP PRIVATE (never commit to git)
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm")

Keystore: android/app/liftoo-upload-keystore.jks
Alias: $KeyAlias
Store password: $StorePassword
Key password: $KeyPassword

Play Console → App integrity → Upload key certificate (SHA-1 / SHA-256):
Run: .\scripts\verify-playstore-signing.ps1
"@
Write-Utf8NoBom $credsPath $creds

Write-Host ""
Write-Host "Play Store upload keystore ready." -ForegroundColor Green
Write-Host "Keystore: $keystorePath"
Write-Host "Config:   $keyPropsPath"
Write-Host "Passwords: $credsPath (local only, gitignored)"
Write-Host ""
Write-Host "Next: .\scripts\build-playstore.ps1"
