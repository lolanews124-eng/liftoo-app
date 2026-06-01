import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const AppLoader({super.key, this.message, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.05, 1.05), duration: 900.ms, curve: Curves.easeInOut)
            .then()
            .scale(begin: const Offset(1.05, 1.05), end: const Offset(0.92, 0.92), duration: 900.ms),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }
    return Padding(padding: const EdgeInsets.all(32), child: Center(child: content));
  }
}
