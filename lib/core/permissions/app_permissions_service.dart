import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Requests every runtime permission once when the app opens (cold start).
class AppPermissionsService {
  static var _requested = false;

  static Future<void> requestAllAtStartup() async {
    if (kIsWeb || _requested) return;
    _requested = true;

    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
    ];

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      permissions.add(Permission.photos);
    }

    for (final permission in permissions) {
      try {
        final status = await permission.status;
        if (status.isGranted || status.isLimited) continue;
        if (status.isPermanentlyDenied) continue;
        await permission.request();
      } catch (_) {
        // Plugin unavailable on some platforms — continue with others.
      }
    }
  }
}
