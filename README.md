# Liftoo Frontend

Flutter mobile app for customers and assistants.

## Run

```bash
flutter pub get
flutter run
```

From project root:

```powershell
.\start-frontend.ps1
```

## API URL

Edit `apiUrl` in `lib/core/config/app_config.dart`.

## Google Maps (map display only)

1. Set `AppConfig.googleMapsApiKey` in `lib/core/config/app_config.dart`
2. Set the same key in `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
3. Set the same key in `ios/Runner/Info.plist` (`GMSApiKey`)

Address search, reverse geocode, and autocomplete go through the backend (`/api/v1/geocode/*`) — no Google Places calls from the app.
