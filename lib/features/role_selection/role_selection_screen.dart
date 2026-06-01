import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/liftoo_logo.dart';
import '../auth/providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _select(BuildContext context, WidgetRef ref, AppRole role) async {
    HapticFeedback.selectionClick();
    await ref.read(authProvider.notifier).setRole(role);
    if (!context.mounted) return;
    context.go(role == AppRole.assistant ? '/assistant' : '/customer');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiftooLogo(fontSize: 26),
              const SizedBox(height: 32),
              const Text(
                'How would you\nlike to continue?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                'You can switch roles later from your profile.',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 14),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                title: 'Customer',
                subtitle: 'Book assistants for your shopping trips',
                icon: Icons.person_outline_rounded,
                accent: AppColors.primary,
                isPrimary: true,
                onTap: () => _select(context, ref, AppRole.customer),
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 14),
              _RoleCard(
                title: 'Assistant',
                subtitle: 'Earn by helping others shop',
                icon: Icons.work_outline_rounded,
                accent: AppColors.charcoal,
                isPrimary: false,
                onTap: () => _select(context, ref, AppRole.assistant),
              ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.08, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isPrimary;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? accent : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isPrimary ? 0 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: isPrimary
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withValues(alpha: 0.2) : accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: isPrimary ? Colors.white : accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isPrimary ? Colors.white : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isPrimary ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: isPrimary ? Colors.white70 : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
