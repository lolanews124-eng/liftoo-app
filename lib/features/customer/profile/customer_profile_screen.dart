import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/legal/legal_links.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../home/home_sheets.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _updatingAvatar = false;

  Future<void> _switchRole(BuildContext context, AppRole role) async {
    await ref.read(authProvider.notifier).setRole(role);
    if (!context.mounted) return;
    context.go(role == AppRole.assistant ? '/assistant' : '/customer');
  }

  Future<void> _onAvatarPicked(String? path) async {
    if (path == null) return;
    setState(() => _updatingAvatar = true);
    try {
      final user = ref.read(authProvider).user;
      await ref.read(authProvider.notifier).completeProfile(
            name: user?.name ?? 'User',
            phone: user?.phone,
            avatarUrl: path,
          );
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _updatingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      name: user?.name,
                      phone: user?.phone,
                      avatarUrl: user?.avatarUrl,
                      radius: 44,
                      editable: true,
                      onPhotoPicked: _onAvatarPicked,
                    ),
                    if (_updatingAvatar)
                      const SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('+91 ${user.phone}', style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text('Tap photo to change', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LiftooCard(
            onTap: () => _switchRole(context, AppRole.assistant),
            child: const Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(child: Text('Switch to Assistant Mode', style: TextStyle(fontWeight: FontWeight.w700))),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tile(Icons.location_on_outlined, 'Saved addresses', () => context.push('/customer/addresses')),
          _tile(Icons.help_outline, 'Help & Support', () => context.push('/support')),
          _tile(Icons.account_balance_wallet_outlined, 'Wallet', () => context.go('/customer/wallet')),
          _tile(Icons.card_giftcard_outlined, 'Referral', () => context.push('/referral')),
          _tile(Icons.history, 'Booking history', () => context.go('/customer/bookings')),
          _tile(Icons.headset_mic_outlined, 'Support', () => showSupportSheet(context)),
          _tile(Icons.help_outline, 'Help', () => showHelpSheet(context)),
          _tile(Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
          _tile(Icons.policy_outlined, 'Legal & policies', () => openLegalIndex()),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiftooCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
