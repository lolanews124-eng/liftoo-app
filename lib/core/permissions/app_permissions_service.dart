import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions — notifications at cold start; others when a feature needs them.
class AppPermissionsService {
  static var _notificationsRequested = false;

  static Future<void> requestNotificationsAtStartup() async {
    if (kIsWeb || _notificationsRequested) return;
    _notificationsRequested = true;
    await _request(Permission.notification);
  }

  static Future<bool> ensureMediaAccess() async {
    if (kIsWeb) return true;
    final permissions = <Permission>[Permission.camera];
    if (Platform.isAndroid || Platform.isIOS) {
      permissions.add(Permission.photos);
    }
    for (final permission in permissions) {
      final granted = await _request(permission);
      if (!granted) return false;
    }
    return true;
  }

  static Future<bool> ensureLocationAccess() async {
    if (kIsWeb) return true;
    return _request(Permission.locationWhenInUse);
  }

  static Future<bool> _request(Permission permission) async {
    try {
      var status = await permission.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) return false;
      status = await permission.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }
}
