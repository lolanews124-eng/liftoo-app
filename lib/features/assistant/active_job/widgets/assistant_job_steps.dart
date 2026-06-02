import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Step-by-step progress for assistant active job (Rapido-style).
class AssistantJobSteps extends StatelessWidget {
  final String status;

  const AssistantJobSteps({super.key, required this.status});

  int get _currentIndex => switch (status) {
        'assigned' => 1,
        'arriving' => 2,
        'started' => 3,
        'completed' => 4,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    const steps = ['Received', 'Accepted', 'On the way', 'Started', 'Done'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i <= _currentIndex ? AppColors.success : Colors.grey.shade300,
                ),
              ),
            _StepDot(
              label: steps[i],
              state: i < _currentIndex
                  ? _StepState.done
                  : i == _currentIndex
                      ? _StepState.active
                      : _StepState.upcoming,
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _StepDot extends StatelessWidget {
  final String label;
  final _StepState state;

  const _StepDot({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.primary,
      _StepState.upcoming => AppColors.textSecondary.withValues(alpha: 0.45),
    };
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: state == _StepState.done
              ? Icon(Icons.check, size: 14, color: color)
              : state == _StepState.active
                  ? Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
