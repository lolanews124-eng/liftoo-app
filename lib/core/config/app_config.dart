import 'package:flutter/foundation.dart';

class AppConfig {
  /// API base URL — pass via --dart-define=API_BASE_URL for release/Play Store builds.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return kReleaseMode ? 'https://api.liftoo.in' : 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
        return kReleaseMode ? 'https://api.liftoo.in' : 'http://localhost:3000';
      default:
        return kReleaseMode ? 'https://api.liftoo.in' : 'http://localhost:3000';
    }
  }

  static String get socketUrl {
    const fromEnv = String.fromEnvironment('SOCKET_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return apiBaseUrl;
  }

  /// Customer web app (policies, marketing) — override via --dart-define=WEB_APP_URL
  static String get webAppBaseUrl {
    const fromEnv = String.fromEnvironment('WEB_APP_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5174';
    return kReleaseMode ? 'https://liftoo.in' : 'http://10.0.2.2:5174';
  }

  static String legalUrl(String slug) => '$webAppBaseUrl/legal/$slug';
  static String get legalIndexUrl => '$webAppBaseUrl/legal';
}
