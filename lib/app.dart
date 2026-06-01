import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/geocode_bootstrap.dart';
import 'core/layout/mobile_viewport.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/no_internet_banner.dart';



class LiftooApp extends ConsumerWidget {

  const LiftooApp({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);



    return GeocodeBootstrap(
      child: MaterialApp.router(
        title: 'Liftoo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) {
          return AppScrollWrapper(
            child: Column(
              children: [
                const NoInternetBanner(),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          );
        },
      ),
    );

  }

}
