import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/network/error_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class DeleteAccountButton extends ConsumerStatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  ConsumerState<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<DeleteAccountButton> {
  bool _loading = false;

  Future<void> _confirmAndDelete() async {
    final walletBalance = ref.read(authProvider).user?.walletBalance ?? 0;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently removes your personal data from Liftoo. Booking and payment records may be kept as required by law.',
            ),
            if (walletBalance > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Your wallet balance (₹${walletBalance.toStringAsFixed(0)}) will be forfeited.',
                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'You can also email ${AppConfig.accountDeletionEmail} from your registered email.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) context.go('/auth/login');
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _loading ? null : _confirmAndDelete,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : const Text(
              'Delete account',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
    );
  }
}
