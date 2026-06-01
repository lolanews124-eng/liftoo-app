import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/network/network_errors.dart';
import '../../core/theme/app_colors.dart';
import 'gradient_button.dart';

enum ErrorScreenType { offline, server, notFound, generic }

class ErrorScreen extends StatelessWidget {
  final ErrorScreenType type;
  final String? message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorScreen({
    super.key,
    this.type = ErrorScreenType.generic,
    this.message,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  factory ErrorScreen.offline({VoidCallback? onRetry}) => ErrorScreen(
        type: ErrorScreenType.offline,
        message: NetworkErrors.noInternet,
        onRetry: onRetry,
      );

  IconData get _icon => switch (type) {
        ErrorScreenType.offline => Icons.wifi_off_rounded,
        ErrorScreenType.server => Icons.cloud_off_outlined,
        ErrorScreenType.notFound => Icons.search_off_rounded,
        ErrorScreenType.generic => Icons.error_outline_rounded,
      };

  String get _title => message ?? switch (type) {
        ErrorScreenType.offline => NetworkErrors.noInternet,
        ErrorScreenType.server => 'Server unavailable',
        ErrorScreenType.notFound => 'Not found',
        ErrorScreenType.generic => 'Something went wrong',
      };

  String get _subtitle => switch (type) {
        ErrorScreenType.offline => 'Check your mobile data or Wi‑Fi, then try again.',
        ErrorScreenType.server => 'Our servers are busy. Please try again shortly.',
        ErrorScreenType.notFound => 'The page or item you’re looking for doesn’t exist.',
        ErrorScreenType.generic => 'Please try again in a moment.',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 44, color: AppColors.primary.withValues(alpha: 0.7)),
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(_title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(_subtitle, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5))
                .animate()
                .fadeIn(delay: 180.ms),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: GradientButton(label: 'Try again', onPressed: onRetry!),
              ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1, end: 0),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
