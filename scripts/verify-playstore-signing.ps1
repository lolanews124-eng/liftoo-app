# Verifies upload keystore + prints SHA-1/SHA-256 for Play Console / Firebase.
# Usage: .\scripts\verify-playstore-signing.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$keyPropsPath = Join-Path $root "android\key.properties"
$keystorePath = Join-Path $root "android\app\liftoo-upload-keystore.jks"

if (-not (Test-Path $keyPropsPath)) {
    Write-Error "Missing android/key.properties. Run .\scripts\setup-playstore-keystore.ps1 first."
}
if (-not (Test-Path $keystorePath)) {
    Write-Error "Missing android/app/liftoo-upload-keystore.jks"
}

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
    throw "keytool not found."
}

$props = @{}
Get-Content $keyPropsPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $props[$parts[0].Trim()] = $parts[1].Trim()
    }
}

$alias = $props["keyAlias"]
$storePass = $props["storePassword"]
$keytool = Find-Keytool

Write-Host "Upload keystore certificate fingerprints:" -ForegroundColor Cyan
& $keytool -list -v -keystore $keystorePath -alias $alias -storepass $storePass

Write-Host ""
Write-Host "Use SHA-1 / SHA-256 in:" -ForegroundColor Green
Write-Host "  • Firebase Console → Project settings → Your apps → Add fingerprint"
Write-Host "  • Play Console → App integrity (after first AAB upload)"
