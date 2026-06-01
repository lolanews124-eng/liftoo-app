import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';

String formatServiceDuration(Duration d) {
  if (d.inHours > 0) {
    final mins = d.inMinutes.remainder(60);
    return mins > 0 ? '${d.inHours} hr ${mins} min' : '${d.inHours} hr';
  }
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} sec';
}

/// Shows service start/end times after payment.
Future<void> showServiceTimeSummary(BuildContext context, BookingModel booking) {
  final start = booking.serviceStartedAt;
  final end = booking.serviceCompletedAt;
  final duration = booking.serviceDuration;
  final assistantName = booking.assistant?['name'] as String? ?? 'Your assistant';
  final timeFmt = DateFormat('h:mm a');
  final dateFmt = DateFormat('d MMM yyyy');

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('Service completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '$assistantName helped you shop',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.35),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  if (start != null) _timeRow(Icons.play_circle_outline, 'Started', '${dateFmt.format(start)} • ${timeFmt.format(start)}'),
                  if (start != null && end != null) const SizedBox(height: 12),
                  if (end != null) _timeRow(Icons.stop_circle_outlined, 'Ended', '${dateFmt.format(end)} • ${timeFmt.format(end)}'),
                  if (duration != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Total time', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Text(
                          formatServiceDuration(duration),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue to review', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _timeRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
          ],
        ),
      ),
    ],
  );
}
