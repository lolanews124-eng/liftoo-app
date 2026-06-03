import 'package:firebase_core/firebase_core.dart';
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
import 'features/auth/providers/auth_provider.dart';
import 'core/push/push_notification_service.dart';

Future<void> _waitForAuthReady(ProviderContainer container) async {
  const maxAttempts = 120;
  for (var i = 0; i < maxAttempts; i++) {
    if (!container.read(authProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> _initFirebase() async {
  if (kIsWeb) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Firebase] init skipped: $e');
    }
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      container.read(referralStorageProvider).savePendingCode(ref);
    }
  });
  appLinks.getInitialLink().then((uri) {
    final ref = uri?.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      container.read(referralStorageProvider).savePendingCode(ref);
    }
  });

  await Future.wait([
    Future<void>.delayed(const Duration(seconds: 2)),
    AppPermissionsService.requestAllAtStartup(),
    _waitForAuthReady(container),
    PushNotificationService.instance.init(container),
  ]);

  FlutterNativeSplash.remove();

  runApp(UncontrolledProviderScope(container: container, child: const LiftooApp()));
}
