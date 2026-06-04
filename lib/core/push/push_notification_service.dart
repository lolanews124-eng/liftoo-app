import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Registers FCM token with Liftoo API after login.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  ProviderContainer? _container;

  Future<void> init(ProviderContainer container) async {
    _container = container;
    if (kIsWeb || _initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      // Android: notification permission is handled by AppPermissionsService after UI is visible.
      if (Platform.isIOS) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      messaging.onTokenRefresh.listen((token) async {
        final c = _container;
        if (c != null && await _hasAuthSession(c)) {
          await _syncToken(c, token);
        }
      });

      final token = await messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token != null && await _hasAuthSession(container)) {
        await _syncToken(container, token);
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] init skipped: $e');
      }
    }
  }

  Future<void> syncAfterLogin(Ref ref) async {
    if (!_initialized) {
      await init(ref.container);
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _syncToken(ref.container, token);
    } catch (_) {}
  }

  Future<void> clearToken(Ref ref) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put<Map<String, dynamic>>('/api/v1/users/me/fcm-token', data: {'token': ''});
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<bool> _hasAuthSession(ProviderContainer container) async {
    final access = await container.read(tokenStorageProvider).getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> _syncToken(ProviderContainer container, String token) async {
    if (token.isEmpty) return;
    if (!await _hasAuthSession(container)) return;
    try {
      final api = container.read(apiClientProvider);
      await api.put<Map<String, dynamic>>('/api/v1/users/me/fcm-token', data: {'token': token});
      if (kDebugMode) debugPrint('[FCM] token registered with server');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] token sync failed: $e');
    }
  }
}
