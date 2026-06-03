import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

String? assistantCodeFrom(Map<String, dynamic>? assistant) {
  if (assistant == null) return null;
  final profile = assistant['assistantProfile'] as Map<String, dynamic>?;
  final code = profile?['assistantCode'] as String?;
  if (code == null || code.trim().isEmpty) return null;
  return code.trim();
}

String assistantNameFrom(Map<String, dynamic>? assistant) =>
    (assistant?['name'] as String?)?.trim().isNotEmpty == true ? assistant!['name'] as String : 'Assistant';

/// One-line label: "Rahul · ID Liftoo-2026-0001"
String assistantSummaryLine(Map<String, dynamic>? assistant) {
  final name = assistantNameFrom(assistant);
  final code = assistantCodeFrom(assistant);
  if (code != null) return '$name · ID $code';
  return name;
}

/// Prominent ID badge for customer to verify physical ID card.
class AssistantIdBadge extends StatelessWidget {
  final Map<String, dynamic>? assistant;
  final bool compact;

  const AssistantIdBadge({super.key, required this.assistant, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final code = assistantCodeFrom(assistant);
    if (code == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined, color: Colors.white.withValues(alpha: 0.9), size: compact ? 16 : 18),
          const SizedBox(width: 8),
          Text(
            'Assistant ID: $code',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
