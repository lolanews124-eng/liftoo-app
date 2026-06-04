import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../../firebase_options.dart';

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

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await _requestNotificationPermission(messaging);

      messaging.onTokenRefresh.listen((token) async {
        final c = _container;
        if (c != null && await _hasAuthSession(c)) {
          await _syncToken(c, token);
        }
      });

      _initialized = true;
      await syncTokenIfLoggedIn(container);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] init failed: $e');
      }
    }
  }

  Future<void> syncAfterLogin(Ref ref) async {
    if (!_initialized) {
      await init(ref.container);
    }
    await syncTokenIfLoggedIn(ref.container);
  }

  Future<void> syncTokenIfLoggedIn(ProviderContainer container) async {
    if (!_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!await _hasAuthSession(container)) return;

    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      if (token != null) {
        await _syncToken(container, token);
      } else if (kDebugMode) {
        debugPrint('[FCM] getToken returned null — check Firebase config / Play Services');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] syncTokenIfLoggedIn failed: $e');
    }
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

  Future<void> _requestNotificationPermission(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      return;
    }
    if (Platform.isAndroid) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
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
