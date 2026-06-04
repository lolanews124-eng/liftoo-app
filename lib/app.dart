import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/geocode_bootstrap.dart';
import 'core/layout/mobile_viewport.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/realtime/in_app_notification_banner.dart';
import 'core/realtime/notification_listener.dart';
import 'core/push/fcm_foreground_listener.dart';
import 'features/assistant/requests/assistant_request_listener.dart';
import 'features/auth/providers/auth_provider.dart';
import 'shared/widgets/no_internet_banner.dart';

class LiftooApp extends ConsumerStatefulWidget {
  const LiftooApp({super.key});

  @override
  ConsumerState<LiftooApp> createState() => _LiftooAppState();
}

class _LiftooAppState extends ConsumerState<LiftooApp> {
  var _splashRemoved = false;

  void _removeSplashIfReady(bool authReady) {
    if (_splashRemoved || !authReady) return;
    _splashRemoved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    _removeSplashIfReady(!auth.isLoading);

    if (auth.isLoading) {
      return MaterialApp(
        title: 'Liftoo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    final isAssistant = ref.watch(authProvider.select((s) => s.user?.activeRole == 'assistant'));
    final loggedIn = ref.watch(authProvider.select((s) => s.user != null));

    return GeocodeBootstrap(
      child: MaterialApp.router(
        title: 'Liftoo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) {
          Widget body = AppScrollWrapper(
            child: Column(
              children: [
                const NoInternetBanner(),
                const InAppNotificationBanner(),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          );
          if (loggedIn) {
            body = FcmForegroundListener(
              child: NotificationRealtimeListener(child: body),
            );
          }
          if (isAssistant) {
            body = AssistantRequestListener(child: body);
          }
          return body;
        },
      ),
    );
  }
}
