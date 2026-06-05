# Play Store — Internal / Closed test release

Step-by-step guide to publish Liftoo on Google Play **Internal testing** (fastest way to test with real users).

## 1. One-time signing setup (this machine)

Keystore is already configured if these files exist:

| File | Purpose |
|------|---------|
| `android/app/liftoo-upload-keystore.jks` | Upload signing key (never lose this) |
| `android/key.properties` | Passwords for Gradle (gitignored) |
| `android/KEYSTORE_CREDENTIALS.local.txt` | Local password backup (gitignored) |

**New machine / fresh clone:**

```powershell
cd c:\Liftoo\frontend
.\scripts\setup-playstore-keystore.ps1
```

Verify signing + get SHA fingerprints (Firebase / Play):

```powershell
.\scripts\verify-playstore-signing.ps1
```

## 2. Build the AAB

```powershell
cd c:\Liftoo\frontend
.\scripts\build-playstore.ps1
```

Output: `c:\Liftoo\Liftoo-playstore-release.aab`

For the **next** upload, bump `versionCode` (required by Play Store):

```powershell
.\scripts\build-playstore.ps1 -BumpVersion
```

Or edit `pubspec.yaml`: `version: 1.0.0+2` → `1.0.0+3` (number after `+` must increase every upload).

## 3. Create app in Play Console

1. [Google Play Console](https://play.google.com/console) → **Create app**
2. App name: **Liftoo**
3. Default language: English (India) or Hindi
4. App / Game: **App**
5. Free or paid: **Free**
6. Accept declarations

**Fixed app details (do not change after first publish):**

| Field | Value |
|-------|-------|
| Package name | `com.liftoo.liftoo_mobile` |
| Privacy policy | `https://liftoo.in/legal/privacy-policy` |

## 4. Enable Play App Signing

On first AAB upload, Play Console asks to opt in to **Google Play App Signing** — choose **Continue** (recommended).

- You sign with **upload key** (`liftoo-upload-keystore.jks`)
- Google re-signs with **app signing key** for users
- Keep upload keystore safe for all future updates

## 5. Internal testing release

1. **Testing** → **Internal testing** → **Create new release**
2. Upload `Liftoo-playstore-release.aab`
3. Release name: e.g. `1.0.0 (1)` — internal testers only
4. Release notes: short changelog
5. **Save** → **Review release** → **Start rollout to Internal testing**

Add testers:

- **Testers** tab → Create email list → add Gmail addresses
- Share the **opt-in link** with testers

## 6. Required Console sections (before wider rollout)

Complete these in Play Console (can be done while internal test runs):

| Section | What to fill |
|---------|----------------|
| **Store listing** | Short + full description, icon 512×512, feature graphic, phone screenshots |
| **App content** | Privacy policy URL, ads (No), target audience, news app (No) |
| **Data safety** | Location, camera, photos, account info — collected for app functionality |
| **Content rating** | Questionnaire (IARC) |
| **Target audience** | 18+ recommended (marketplace / location) |
| **Account deletion** | In-app: Profile → Delete account; URL/email: `delete@liftoo.in` |

## 7. Firebase (push notifications)

Package in `google-services.json` must match: `com.liftoo.liftoo_mobile` ✓

After first Play upload, add **Play App Signing** SHA-1/SHA-256 from:

**Play Console** → **App integrity** → **App signing key certificate**

to **Firebase** → Project settings → Android app → SHA certificate fingerprints.

## 8. Backend before testers use the app

Deploy backend with account deletion API:

- `DELETE /api/v1/users/me`

Production API URL in app: `https://api.liftoo.in` (`lib/core/config/app_config.dart`).

## 9. Troubleshooting

| Error | Fix |
|-------|-----|
| `Version code X has already been used` | Run `build-playstore.ps1 -BumpVersion` |
| `Upload certificate mismatch` | Use the same `liftoo-upload-keystore.jks` as first upload |
| `key.properties` / signing failed | Re-save `key.properties` as UTF-8 **without BOM** |
| Push not working for testers | Add Play App Signing SHA to Firebase |

## Quick command reference

```powershell
# First-time keystore
.\scripts\setup-playstore-keystore.ps1

# Verify SHA fingerprints
.\scripts\verify-playstore-signing.ps1

# Build AAB
.\scripts\build-playstore.ps1

# Build + bump version for next upload
.\scripts\build-playstore.ps1 -BumpVersion
```
