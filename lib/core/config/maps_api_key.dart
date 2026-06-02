/// Google Maps display key — keep in sync with `backend/.env` → `GOOGLE_MAPS_API_KEY`.
/// Android reads the same value from `.env` via Gradle; override at build with
/// `--dart-define=GOOGLE_MAPS_API_KEY=...` if needed.
const String kMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyC_XJIfUhLxy9H1Wut-ZtZd7b7T08nA2SY',
);
