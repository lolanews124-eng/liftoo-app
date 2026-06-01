import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform-native scroll physics — no fake phone chrome or mock status bars.
class AppScrollWrapper extends StatelessWidget {
  final Widget child;

  const AppScrollWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NativeScrollBehavior(),
      child: child,
    );
  }
}

class _NativeScrollBehavior extends ScrollBehavior {
  const _NativeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    }
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
