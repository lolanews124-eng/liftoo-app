import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/assistant_verification_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/role_switch_guard.dart';
import '../shared/assistant_online_confirm.dart';
import '../shared/assistant_online_service.dart';

class AssistantProfileScreen extends ConsumerStatefulWidget {
  const AssistantProfileScreen({super.key});

  @override
  ConsumerState<AssistantProfileScreen> createState() => _AssistantProfileScreenState();
}

class _AssistantProfileScreenState extends ConsumerState<AssistantProfileScreen> {
  VerificationSummaryModel? _summary;
  bool _loadingSummary = true;
  double _settlementBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final bundle = await ref.read(assistantVerificationRepositoryProvider).getVerification();
      final wallet = await ref.read(walletRepositoryProvider).getWallet();
      if (mounted) {
        setState(() {
          _summary = bundle.summary;
          _settlementBalance = (wallet['balance'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _toggleOnline(bool targetOnline) async {
    final ok = await confirmAssistantOnlineChange(context, targetOnline);
    if (!ok || !mounted) return;
    try {
      await setAssistantOnline(ref, targetOnline);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(targetOnline ? 'You are now online' : 'You are now offline'),
        ),
      );
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final ap = user?.assistantProfile;
    final isOnline = user?.isOnline ?? false;
    final summary = _summary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildProfileHeader(user, ap),
            const SizedBox(height: 16),
            _buildOnlineCard(isOnline),
            const SizedBox(height: 12),
            _buildSettlementWalletCard(context),
            const SizedBox(height: 16),
            _buildVerificationEntry(summary),
            const SizedBox(height: 20),
            if (user?.hasCustomer == true)
              LiftooCard(
                onTap: isOnline
                    ? () => showRoleSwitchBlocked(
                          context,
                          'You are online as an assistant. Turn off online mode first, then switch to customer mode.',
                        )
                    : () async {
                        final ok = await trySwitchRole(context, ref, AppRole.customer);
                        if (ok && context.mounted) context.go('/customer');
                      },
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: isOnline ? AppColors.textSecondary : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch to Customer Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isOnline ? AppColors.textSecondary : AppColors.charcoal,
                            ),
                          ),
                          if (isOnline)
                            const Text(
                              'Go offline first',
                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: isOnline ? AppColors.textSecondary : null),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            LiftooCard(
              onTap: () => context.push('/legal'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Icon(Icons.policy_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(child: Text('Legal & policies', style: TextStyle(fontWeight: FontWeight.w600))),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildSettlementWalletCard(BuildContext context) {
    return LiftooCard(
      onTap: () async {
        final added = await context.push<bool>('/customer/wallet/add', extra: _settlementBalance);
        if (added == true && mounted) _loadSummary();
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settlement wallet', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '₹${_settlementBalance.toStringAsFixed(0)} • Required for cash payments',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user, AssistantProfileModel? ap) {
    return Column(
      children: [
        ProfileAvatar(name: user?.name, phone: user?.phone, avatarUrl: user?.avatarUrl, radius: 44),
        const SizedBox(height: 12),
        Text(user?.name ?? 'Assistant', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          '★ ${ap?.rating.toStringAsFixed(1) ?? '5.0'} • ${ap?.totalJobs ?? 0} jobs completed',
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildOnlineCard(bool isOnline) {
    return LiftooCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
            color: isOnline ? AppColors.success : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOnline ? 'Online' : 'Offline', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  isOnline ? 'Receiving booking requests' : 'Not receiving requests',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            onChanged: _toggleOnline,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationEntry(VerificationSummaryModel? summary) {
    if (_loadingSummary) {
      return const LiftooCard(
        child: SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
      );
    }

    final percent = summary?.completionPercent ?? 0;
    final verified = summary?.verifiedCount ?? 0;
    final total = summary?.totalRequired ?? 11;
    final pending = summary?.pendingCount ?? 0;
    final fullyVerified = summary?.fullyVerified ?? false;

    return LiftooCard(
      onTap: () => context.push('/assistant/verification'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (fullyVerified ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  fullyVerified ? Icons.verified_user : Icons.admin_panel_settings_outlined,
                  color: fullyVerified ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Verification & KYC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      fullyVerified ? 'Fully verified' : '$verified of $total documents verified',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          if (!fullyVerified) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.surface,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$percent% complete', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                if (pending > 0)
                  Text('$pending pending review', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
