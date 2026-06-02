import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BookingAvailabilityBanner extends StatelessWidget {
  final bool loading;
  final int nearbyCount;
  final int matchRadiusKm;
  final VoidCallback? onRetry;

  const BookingAvailabilityBanner({
    super.key,
    required this.loading,
    required this.nearbyCount,
    this.matchRadiusKm = 10,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking assistants near you…',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final available = nearbyCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: available ? AppColors.successLight : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: available ? AppColors.success.withValues(alpha: 0.35) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: available ? AppColors.success : AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? '$nearbyCount assistant${nearbyCount == 1 ? '' : 's'} available nearby'
                      : 'No assistants available right now',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: available ? AppColors.navy : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available
                      ? 'Verified assistants within $matchRadiusKm km of your pickup'
                      : 'Try a different pickup location or check again in a few minutes',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.35),
                ),
              ],
            ),
          ),
          if (!available && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
