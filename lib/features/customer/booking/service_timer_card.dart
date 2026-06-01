import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import 'service_time_summary_dialog.dart';
import '../../../shared/widgets/liftoo_card.dart';

class ServiceTimerCard extends StatefulWidget {
  final BookingModel booking;

  const ServiceTimerCard({super.key, required this.booking});

  @override
  State<ServiceTimerCard> createState() => _ServiceTimerCardState();
}

class _ServiceTimerCardState extends State<ServiceTimerCard> {
  Timer? _tick;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _syncElapsed());
  }

  @override
  void didUpdateWidget(ServiceTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncElapsed();
  }

  void _syncElapsed() {
    final start = widget.booking.serviceStartedAt;
    if (start == null) return;
    final next = DateTime.now().difference(start);
    if (next != _elapsed && mounted) setState(() => _elapsed = next);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.booking.serviceStartedAt;
    if (start == null) return const SizedBox.shrink();

    return LiftooCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Service in progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: const Text('LIVE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              formatServiceDuration(_elapsed),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.charcoal, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Started at ${TimeOfDay.fromDateTime(start).format(context)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
