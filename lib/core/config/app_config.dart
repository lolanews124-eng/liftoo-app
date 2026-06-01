class AppConfig {
  /// API base URL — change this for local dev or production.
  static const apiUrl = 'http://192.168.31.37:5000';

  /// Google Maps SDK key (map display only). Also set in AndroidManifest + iOS AppDelegate.
  static const googleMapsApiKey = '';

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static String legalUrl(String slug) => 'https://liftoo.in/legal/$slug';
  static String get legalIndexUrl => 'https://liftoo.in/legal';
}
