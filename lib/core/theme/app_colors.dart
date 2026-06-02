import 'package:flutter/material.dart';

/// Liftoo brand palette: navy [#001a3e] + pink [#ff0064].
class AppColors {
  static const navy = Color(0xFF001A3E);
  static const primary = Color(0xFFFF0064);
  static const primaryDark = Color(0xFFD90055);
  static const primaryLight = Color(0xFFFFF0F6);
  static const charcoal = navy;
  static const surface = Color(0xFFF5F5F7);
  static const card = Colors.white;
  static const textPrimary = navy;
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFE8F8F0);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFF3E8FF);

  static const gradient = LinearGradient(
    colors: [Color(0xFFFFF0F6), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFFFFE6F0), Color(0xFFFFF8FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const referralGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Color categoryColor(String slug) => switch (slug) {
        'bag_carry' => primary,
        'queue' => const Color(0xFF8B5CF6),
        'senior' => const Color(0xFF10B981),
        'family' => const Color(0xFF3B82F6),
        'festival' => const Color(0xFFEC4899),
        _ => primary,
      };
}
