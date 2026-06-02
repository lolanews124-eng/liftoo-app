import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';

class HomeQuickBookCard extends StatelessWidget {
  final String locationLabel;
  final String serviceLabel;
  final String durationLabel;
  final bool locationLoading;
  final VoidCallback onLocationTap;
  final VoidCallback onServiceTap;
  final VoidCallback onDurationTap;
  final VoidCallback onFindAssistant;

  const HomeQuickBookCard({
    super.key,
    required this.locationLabel,
    required this.serviceLabel,
    required this.durationLabel,
    this.locationLoading = false,
    required this.onLocationTap,
    required this.onServiceTap,
    required this.onDurationTap,
    required this.onFindAssistant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, Color(0xFF002A5C)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Quick Book',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'From ₹49',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Book in under 60 seconds',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
            ),
            const SizedBox(height: 14),
            _QuickField(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: locationLoading ? 'Getting location…' : locationLabel,
              onTap: locationLoading ? null : onLocationTap,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickField(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Service',
                    value: serviceLabel,
                    onTap: onServiceTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickField(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: durationLabel,
                    onTap: onDurationTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Find Assistant',
              icon: Icons.arrow_forward_rounded,
              onPressed: onFindAssistant,
              radius: 14,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _trustChip(Icons.verified_user_outlined, 'Verified'),
                _trustChip(Icons.access_time_rounded, 'On-time'),
                _trustChip(Icons.shield_outlined, 'Secure'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 16),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _QuickField({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
