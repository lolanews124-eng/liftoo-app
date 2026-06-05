import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Inline assistant availability hint on pickup step — no card overlay.
class AssistantAvailabilityStrip extends StatelessWidget {
  final bool loading;
  final int count;
  final int matchRadiusKm;
  final VoidCallback? onRetry;

  const AssistantAvailabilityStrip({
    super.key,
    required this.loading,
    required this.count,
    required this.matchRadiusKm,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking assistants near you…',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      );
    }

    final available = count > 0;
    if (available) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '$count assistant${count == 1 ? '' : 's'} available within $matchRadiusKm km',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.success,
            height: 1.35,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No assistants online nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.primary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try again in a few minutes or change pickup location to a busier area.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 10),
            Material(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Retry',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
