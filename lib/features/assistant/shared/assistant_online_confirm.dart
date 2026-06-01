import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Polished confirmation before assistant toggles online/offline.
Future<bool> confirmAssistantOnlineChange(BuildContext context, bool goingOnline) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black45,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
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
                color: (goingOnline ? AppColors.success : AppColors.charcoal).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                goingOnline ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                size: 32,
                color: goingOnline ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              goingOnline ? 'Go online now?' : 'Go offline?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.charcoal),
            ),
            const SizedBox(height: 10),
            Text(
              goingOnline
                  ? 'Nearby customers will be able to send you booking requests. Ensure your profile and KYC documents are complete.'
                  : 'You will stop receiving new requests. Any active job will continue as usual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: goingOnline ? AppColors.success : AppColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      goingOnline ? 'Go online' : 'Go offline',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
