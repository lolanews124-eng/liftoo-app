import 'maps_api_key.dart';

class AppConfig {
  /// API base URL — change this for local dev or production.
  static const apiUrl = 'https://api.liftoo.in';

  /// Google Maps SDK key (map display only). Also set in AndroidManifest + iOS Info.plist.
  static const googleMapsApiKey = kMapsApiKey;
  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static String legalUrl(String slug) => 'https://liftoo.in/legal/$slug';
  static String get legalIndexUrl => 'https://liftoo.in/legal';

  static const supportEmail = 'contact@liftoo.in';
  static const accountDeletionEmail = 'delete@liftoo.in';
}
