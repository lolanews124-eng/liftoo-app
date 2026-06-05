# Play Store release build

## What is configured

| Layer | Protection |
|-------|------------|
| **Upload keystore** | Signs the AAB (required by Play Store) |
| **R8 / ProGuard** | Shrinks & obfuscates Android/Java code |
| **Dart obfuscation** | `--obfuscate --split-debug-info` on release build |
| **HTTPS only** | Release builds block cleartext HTTP |
| **Debug symbols** | Saved separately for crash deobfuscation (do not upload to Play) |

## One-time setup

```powershell
cd c:\Liftoo\frontend
.\scripts\setup-playstore-keystore.ps1
.\scripts\verify-playstore-signing.ps1
```

Keystore file: `android/app/liftoo-upload-keystore.jks`  
Config: `android/key.properties` (gitignored)

**Internal / closed test release guide:** see [PLAYSTORE_TEST_RELEASE.md](PLAYSTORE_TEST_RELEASE.md)

**Important (Windows):** Save `key.properties` as UTF-8 **without BOM**. PowerShell `Set-Content -Encoding UTF8` adds a BOM and breaks `storePassword` — use Notepad "UTF-8" (not "UTF-8 with BOM") or:

```powershell
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("android\key.properties", $content, $utf8)
```

**Keep the keystore and passwords safe.** If you lose them, you cannot update the app on Play Store.

## Build for Play Store

```powershell
cd c:\Liftoo\frontend
.\scripts\build-playstore.ps1

# Next uploads — bump versionCode (required by Play Store):
.\scripts\build-playstore.ps1 -BumpVersion
```

Output: `c:\Liftoo\Liftoo-playstore-release.aab`

## Upload to Google Play Console

1. [Google Play Console](https://play.google.com/console) → Create app
2. **Release** → **Production** (or Internal testing)
3. Upload `Liftoo-playstore-release.aab`
4. Enable **Google Play App Signing** (recommended — Google re-signs for users)
5. Fill store listing, privacy policy (`https://liftoo.in/legal/privacy-policy`), content rating

## Crash reports (deobfuscation)

If a crash happens in production, use symbol files in:

`build/app/outputs/symbols/`

Upload these mapping files in Play Console under **App bundle explorer** → deobfuscation.

## Change keystore password (optional)

```powershell
keytool -storepasswd -keystore android\app\liftoo-upload-keystore.jks
keytool -keypasswd -alias liftoo-upload -keystore android\app\liftoo-upload-keystore.jks
```

Then update `android/key.properties`.
