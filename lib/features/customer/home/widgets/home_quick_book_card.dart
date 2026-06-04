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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF001A3E), Color(0xFF0A2F5C), Color(0xFF123D6E)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.35),
                                AppColors.primary.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Book',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Book in under 60 seconds',
                                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
                          ),
                          child: const Text(
                            'From ₹49',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StepField(
                      step: 1,
                      icon: Icons.location_on_rounded,
                      label: 'Where',
                      value: locationLoading ? 'Getting location…' : locationLabel,
                      onTap: locationLoading ? null : onLocationTap,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StepField(
                            step: 2,
                            icon: Icons.shopping_bag_outlined,
                            label: 'Service',
                            value: serviceLabel,
                            onTap: onServiceTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StepField(
                            step: 3,
                            icon: Icons.timer_outlined,
                            label: 'Duration',
                            value: durationLabel,
                            onTap: onDurationTap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Find Assistant',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onFindAssistant,
                      radius: 16,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _trustChip(Icons.verified_user_rounded, 'Verified'),
                        _trustChip(Icons.schedule_rounded, 'On-time'),
                        _trustChip(Icons.lock_outline_rounded, 'Secure'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.45), size: 15),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StepField extends StatelessWidget {
  final int step;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StepField({
    required this.step,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
