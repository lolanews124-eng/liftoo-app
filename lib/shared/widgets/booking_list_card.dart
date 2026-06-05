import 'package:flutter/material.dart';
import '../../core/utils/app_datetime.dart';

import '../../core/theme/app_colors.dart';
import '../models/booking_model.dart';
import 'assistant_info.dart';
import 'booking_detail_sheet.dart';

class BookingListCard extends StatelessWidget {
  final BookingModel booking;
  final String tabStatus;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final bool isAssistantView;

  const BookingListCard({
    super.key,
    required this.booking,
    required this.tabStatus,
    required this.onTap,
    this.onCancel,
    this.isAssistantView = false,
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

  String _statusLabel() {
    if (booking.isPaymentPending) return 'Payment due';
    return formatBookingStatusLabel(booking.status);
  }

  Color _statusColor() {
    if (booking.isPaymentPending) return AppColors.warning;
    return bookingStatusColor(booking.status);
  }

  String _amountLabel() {
    if (isAssistantView) {
      final earn = booking.assistantEarningAmount ?? (booking.serviceFee * 0.8);
      return 'Earn ₹${earn.toStringAsFixed(0)}';
    }
    return '₹${booking.totalAmount.toStringAsFixed(0)}';
  }

  String? _personLabel() {
    if (isAssistantView) {
      final name = booking.customer?['name'] as String?;
      return name != null && name.isNotEmpty ? name : null;
    }
    if (booking.assistant == null) return null;
    return assistantSummaryLine(booking.assistant);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final slug = booking.category?.slug;
    final accent = slug != null ? AppColors.categoryColor(slug) : AppColors.primary;
    final personLabel = _personLabel();
    final dateLabel = formatAppDateTime(booking.scheduledAt, pattern: 'MMM d, h:mm a');
    final amountLabel = _amountLabel();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: tabStatus == 'cancelled' ? AppColors.error.withValues(alpha: 0.7) : accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_categoryIcon(slug), color: accent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                booking.category?.name ?? (isAssistantView ? 'Job' : 'Booking'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.navy,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(),
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _shortVenue(booking.venueName),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _InlineMeta(Icons.calendar_today_outlined, dateLabel),
                                  _dot(),
                                  _InlineMeta(
                                    isAssistantView ? Icons.savings_outlined : Icons.payments_outlined,
                                    amountLabel,
                                    emphasized: true,
                                  ),
                                  if (personLabel != null) ...[
                                    _dot(),
                                    _InlineMeta(
                                      isAssistantView ? Icons.person_outline_rounded : Icons.support_agent_outlined,
                                      personLabel,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (onCancel != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: onCancel,
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textSecondary.withValues(alpha: 0.45),
                              ),
                          ],
                        ),
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

  Widget _dot() => Text('·', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12));
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _InlineMeta(this.icon, this.label, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: emphasized ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: emphasized ? AppColors.primary : AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
