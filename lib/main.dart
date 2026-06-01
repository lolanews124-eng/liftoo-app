import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(UncontrolledProviderScope(container: container, child: const LiftooApp()));
}
