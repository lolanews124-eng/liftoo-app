import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/screen_safe_padding.dart';
import '../../../core/legal/legal_links.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/delete_account_button.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/role_switch_guard.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  Future<void> _switchRole(BuildContext context, AppRole role) async {
    final ok = await trySwitchRole(context, ref, role);
    if (!ok || !context.mounted) return;
    context.go(role == AppRole.assistant ? '/assistant' : '/customer');
  }

  Future<void> _onAvatarPicked(String? path) async {
    if (path == null) return;
    context.push('/customer/profile/edit');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.navy),
            ),
          ),
          SliverPadding(
            padding: shellScrollPadding(context, top: 4),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileHeader(
                  user: user,
                  onPhotoPicked: _onAvatarPicked,
                ),
                if (user?.hasAssistant == true) ...[
                  const SizedBox(height: 16),
                  _RoleSwitchCard(onTap: () => _switchRole(context, AppRole.assistant)),
                ],
                const SizedBox(height: 24),
                _SectionLabel('Account'),
                const SizedBox(height: 10),
                _MenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Name, mobile & photo',
                      onTap: () => context.push('/customer/profile/edit'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved addresses',
                      subtitle: 'Home, work & more',
                      onTap: () => context.push('/customer/addresses'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Balance & transactions',
                      onTap: () => context.go('/customer/wallet'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel('Rewards'),
                const SizedBox(height: 10),
                _MenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Refer & earn',
                      subtitle: 'Invite friends, get rewards',
                      accent: AppColors.purple,
                      onTap: () => context.push('/referral'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel('Support'),
                const SizedBox(height: 10),
                _MenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Help & Support',
                      subtitle: 'FAQs, contact & tickets',
                      onTap: () => context.push('/support'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.policy_outlined,
                      title: 'Legal & policies',
                      subtitle: 'Terms, privacy & more',
                      onTap: () async {
                        final ok = await openLegalIndex();
                        if (!ok && context.mounted) {
                          showAppErrorSnackBar(
                            context,
                            Exception('Could not open liftoo.in. Check browser app.'),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _LogoutButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                ),
                const Center(child: DeleteAccountButton()),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final void Function(String? path) onPhotoPicked;

  const _ProfileHeader({
    required this.user,
    required this.onPhotoPicked,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.navy.withValues(alpha: 0.92),
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: ProfileAvatar(
                  name: user?.name,
                  phone: user?.phone,
                  avatarUrl: user?.avatarUrl,
                  radius: 46,
                  editable: true,
                  onPhotoPicked: onPhotoPicked,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          if (u != null && u.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              u.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
          if (u != null && u.phone != null && u.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '+91 ${u.phone}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Tap photo to update',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RoleSwitchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight,
                Colors.white,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assistant mode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        'Switch to accept booking requests',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accent;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent,
    required this.onTap,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_ProfileMenuItem> items;

  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _MenuRow(item: items[i]),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: AppColors.surface,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _ProfileMenuItem item;

  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.accent ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
