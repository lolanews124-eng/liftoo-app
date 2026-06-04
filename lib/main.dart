import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/permissions/app_permissions_service.dart';
import 'core/providers/providers.dart';
import 'core/push/fcm_background_handler.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/push/push_notification_service.dart';

Future<void> _initFirebase() async {
  if (kIsWeb) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
    }
  } on TimeoutException {
    if (kDebugMode) debugPrint('[Firebase] init timed out — continuing without FCM');
  } catch (e) {
    if (kDebugMode) debugPrint('[Firebase] init skipped: $e');
  }
}

void _bindAppLinks(ProviderContainer container) {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      container.read(referralStorageProvider).savePendingCode(ref);
    }
  });
  unawaited(
    appLinks.getInitialLink().then((uri) {
      final ref = uri?.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        container.read(referralStorageProvider).savePendingCode(ref);
      }
    }),
  );
}

/// Permissions first, then FCM init + token sync (background push needs a valid token on the server).
Future<void> _deferredStartup(ProviderContainer container) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  try {
    await AppPermissionsService.requestAllAtStartup().timeout(
      const Duration(seconds: 45),
      onTimeout: () {},
    );
    await PushNotificationService.instance.init(container).timeout(
      const Duration(seconds: 25),
      onTimeout: () {},
    );
    await PushNotificationService.instance.syncTokenIfLoggedIn(container);
  } catch (e) {
    if (kDebugMode) debugPrint('[Startup] push setup failed: $e');
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await _initFirebase();

  if (kDebugMode) {
    debugPrint('[Config] apiUrl=${AppConfig.apiUrl}');
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final container = ProviderContainer();
  container.read(authProvider);
  _bindAppLinks(container);

  runApp(UncontrolledProviderScope(container: container, child: const LiftooApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_deferredStartup(container));
  });
}
