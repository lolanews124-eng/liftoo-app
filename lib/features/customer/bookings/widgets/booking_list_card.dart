import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/assistant_info.dart';
import '../../../../shared/widgets/booking_detail_sheet.dart';

class BookingListCard extends StatelessWidget {
  final BookingModel booking;
  final String tabStatus;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const BookingListCard({
    super.key,
    required this.booking,
    required this.tabStatus,
    required this.onTap,
    this.onCancel,
  });

  IconData _categoryIcon(String? slug) => switch (slug) {
        'bag_carry' => Icons.shopping_bag_outlined,
        'queue' => Icons.groups_outlined,
        'family' => Icons.family_restroom_outlined,
        'senior' => Icons.elderly_outlined,
        'festival' => Icons.celebration_outlined,
        _ => Icons.event_note_outlined,
      };

  String _shortVenue(String venue) {
    final parts = venue.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return venue;
    if (parts.length == 1) return parts.first;
    return '${parts.first}, ${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = bookingStatusColor(booking.status);
    final slug = booking.category?.slug;
    final accent = slug != null ? AppColors.categoryColor(slug) : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_categoryIcon(slug), color: accent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.category?.name ?? 'Booking',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _shortVenue(booking.venueName),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                formatBookingStatusLabel(booking.status),
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetaChip(
                                icon: Icons.calendar_today_outlined,
                                label: DateFormat('MMM d, h:mm a').format(booking.scheduledAt),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _MetaChip(
                              icon: Icons.payments_outlined,
                              label: '₹${booking.totalAmount.toStringAsFixed(0)}',
                              emphasized: true,
                            ),
                          ],
                        ),
                        if (booking.assistant != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  assistantSummaryLine(booking.assistant),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            ],
                          ),
                        ] else
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          ),
                        if (onCancel != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onCancel,
                              child: const Text('Cancel booking', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: emphasized ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized ? AppColors.primary : AppColors.navy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
