import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav tabs: back from non-home tab goes to home instead of closing the app.
class TabShellBackScope extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int homeBranchIndex;
  final int localTabIndex;
  final Widget child;

  const TabShellBackScope({
    super.key,
    required this.navigationShell,
    required this.homeBranchIndex,
    required this.localTabIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: localTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(homeBranchIndex);
      },
      child: child,
    );
  }
}

/// Full-screen pushed routes: pop when possible, otherwise return to role home.
class RootBackScope extends StatelessWidget {
  final Widget child;

  const RootBackScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _fallback(context);
      },
      child: child,
    );
  }

  void _fallback(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    if (path.startsWith('/auth/otp')) {
      context.go('/auth/login');
      return;
    }
    if (path.startsWith('/auth') || path == '/splash' || path == '/role-selection') {
      SystemNavigator.pop();
      return;
    }
    if (path.startsWith('/assistant')) {
      context.go('/assistant');
      return;
    }
    context.go('/customer');
  }
}

/// Multi-step flows: back moves one step at a time before leaving the screen.
class StepBackScope extends StatelessWidget {
  final int step;
  final VoidCallback onStepBack;
  final Widget child;

  const StepBackScope({
    super.key,
    required this.step,
    required this.onStepBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == 0 && context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (step > 0) {
          onStepBack();
          return;
        }
        if (context.canPop()) {
          context.pop();
        }
      },
      child: child,
    );
  }
}
