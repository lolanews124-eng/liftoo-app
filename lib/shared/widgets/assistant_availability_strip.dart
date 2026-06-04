import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shown below map / before price — assistant availability for pickup area.
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Checking assistants near you…',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
              ),
            ),
          ],
        ),
      );
    }

    final available = count > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: available
              ? [const Color(0xFFE8F8F0), Colors.white]
              : [const Color(0xFFFFF1F2), Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: available ? AppColors.success.withValues(alpha: 0.35) : AppColors.error.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (available ? AppColors.success : AppColors.error).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (available ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              available ? Icons.people_alt_rounded : Icons.person_off_outlined,
              color: available ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available ? 'Assistants online nearby' : 'No assistants online nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: available ? AppColors.navy : AppColors.error,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  available
                      ? '$count assistant${count == 1 ? '' : 's'} available within $matchRadiusKm km of your pickup.'
                      : 'Try again in a few minutes or change pickup location to a busier area.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          if (!available && onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}
