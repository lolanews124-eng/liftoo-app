import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/error_snackbar.dart';
import '../../core/providers/providers.dart';
import '../../features/booking/booking_block_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import 'providers/auth_provider.dart';

/// Returns a user-facing reason if role switch must be blocked.
Future<String?> roleSwitchBlockReason(WidgetRef ref, AppRole target) async {
  final user = ref.read(authProvider).user;
  if (user == null) return 'Please sign in again.';

  if (target == AppRole.customer) {
    if (user.isOnline) {
      return 'You are online as an assistant. Turn off online mode first, then switch to customer mode.';
    }
    try {
      final job = await ref.read(bookingRepositoryProvider).getActiveJob();
      if (job != null) {
        return 'Complete your active job and payment before switching to customer mode.';
      }
    } catch (_) {}
  }

  if (target == AppRole.assistant) {
    try {
      final blocking = await ref.read(bookingRepositoryProvider).getCustomerBlockingBooking();
      if (blocking != null) {
        return 'Finish your booking and payment before switching to assistant mode.';
      }
    } catch (_) {}
  }

  return null;
}

Future<bool> showRoleSwitchBlocked(BuildContext context, String message) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cannot switch mode'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return false;
}

Future<bool> trySwitchRole(BuildContext context, WidgetRef ref, AppRole role) async {
  final block = await roleSwitchBlockReason(ref, role);
  if (block != null) {
    if (context.mounted) await showRoleSwitchBlocked(context, block);
    return false;
  }
  try {
    await ref.read(authProvider.notifier).setRole(role);
    return true;
  } catch (e) {
    if (context.mounted) showAppErrorSnackBar(context, e);
    return false;
  }
}
