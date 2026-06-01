import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/permissions/app_permissions_service.dart';
import '../auth/providers/auth_provider.dart';

/// Shown once per cold start ([AppRouter.initialLocation]).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _golaxRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2200)),
      AppPermissionsService.requestAllAtStartup(),
    ]);
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoading) {
      Future.delayed(const Duration(milliseconds: 300), _navigate);
      return;
    }
    final user = auth.user;
    if (user == null) {
      context.go('/auth/login');
    } else if (!user.profileComplete) {
      context.go('/auth/setup-profile');
    } else if (user.activeRole == null) {
      context.go('/role-selection');
    } else if (user.activeRole == 'assistant') {
      context.go('/assistant');
    } else {
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Image.asset(
                  'assets/images/liftoo_logo.png',
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 450.ms)
                    .scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1),
                      duration: 550.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.3,
                    color: Colors.black.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                  children: const [
                    TextSpan(text: 'A Product of '),
                    TextSpan(
                      text: 'GOLAX',
                      style: TextStyle(
                        color: _golaxRed,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}
