import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MapsPlaceholder extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final VoidCallback? onTap;
  final bool showComingSoonBadge;

  const MapsPlaceholder({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 200,
    this.onTap,
    this.showComingSoonBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(6, (i) {
                return Positioned(
                  left: 20.0 + (i * 28) % 120,
                  top: 30.0 + (i * 17) % 80,
                  child: Icon(
                    Icons.circle,
                    size: 4 + (i % 3) * 2,
                    color: AppColors.primary.withValues(alpha: 0.15 + i * 0.05),
                  ),
                );
              }),
              Positioned(
                right: 24,
                top: 24,
                child: Icon(Icons.map_outlined, size: 32, color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
                        ),
                      ],
                      if (showComingSoonBadge) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Maps coming soon',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
