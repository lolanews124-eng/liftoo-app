import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const StatusTimeline({super.key, required this.currentStatus});

  static const steps = [
    ('searching', 'Searching'),
    ('assigned', 'Assigned'),
    ('arriving', 'Arriving'),
    ('started', 'Started'),
    ('completed', 'Completed'),
  ];

  int get _currentIndex {
    final i = steps.indexWhere((s) => s.$1 == currentStatus);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= _currentIndex;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.primary : Colors.grey.shade200,
                    ),
                    child: active
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    color: i < _currentIndex
                        ? AppColors.primary
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
