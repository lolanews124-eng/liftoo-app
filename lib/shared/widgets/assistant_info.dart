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

/// Name only — use [AssistantIdLine] below rating/review for the ID.
String assistantSummaryLine(Map<String, dynamic>? assistant) => assistantNameFrom(assistant);

/// Pink bold ID below assistant name / rating row: `ID: Liftoo-2026-0003`
class AssistantIdLine extends StatelessWidget {
  final Map<String, dynamic>? assistant;

  const AssistantIdLine({super.key, required this.assistant});

  @override
  Widget build(BuildContext context) {
    final code = assistantCodeFrom(assistant);
    if (code == null) return const SizedBox.shrink();

    return Text(
      'ID: $code',
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.2,
      ),
    );
  }
}
