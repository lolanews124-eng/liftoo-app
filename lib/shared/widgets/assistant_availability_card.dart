import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/booking_tracking_model.dart';
import 'liftoo_card.dart';

class AssistantAvailabilityCard extends StatelessWidget {
  final BookingSearchAvailability availability;
  final bool pulsing;

  const AssistantAvailabilityCard({
    super.key,
    required this.availability,
    this.pulsing = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiftooCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  availability.nearbyAvailable > 0 ? Icons.people_alt_rounded : Icons.search_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      availability.message,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${availability.areaLabel} · within ${availability.matchRadiusKm.toStringAsFixed(0)} km',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (pulsing)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary.withValues(alpha: 0.85)),
                ),
            ],
          ),
          if (availability.zones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Available by area', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            ...availability.zones.map(
              (z) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(z.label, style: const TextStyle(fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${z.count} online',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (availability.notifiedCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Notified ${availability.notifiedCount} nearby assistant${availability.notifiedCount == 1 ? '' : 's'}…',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
