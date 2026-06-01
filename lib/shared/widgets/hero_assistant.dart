import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Lightweight hero illustration — no full-screen mockup image.
class HeroAssistantIllustration extends StatelessWidget {
  const HeroAssistantIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 8,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 20,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 0,
            child: _bag(Icons.shopping_bag, AppColors.primary, 28),
          ),
          Positioned(
            right: 52,
            bottom: 4,
            child: _bag(Icons.shopping_bag_outlined, const Color(0xFF8B5CF6), 22),
          ),
          Positioned(
            right: 28,
            bottom: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 12),
                  SizedBox(width: 2),
                  Text('4.8', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bag(IconData icon, Color color, double size) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
