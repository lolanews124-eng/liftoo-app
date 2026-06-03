import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../models/booking_model.dart';
import 'assistant_info.dart';
import 'status_timeline.dart';

/// Human-readable booking status for UI.
String formatBookingStatusLabel(String status) => switch (status) {
      'completed' => 'Complete',
      'cancelled' => 'Cancelled',
      'searching' => 'Searching',
      'assigned' => 'Accepted',
      'arriving' => 'On the way',
      'started' => 'In progress',
      'pending' => 'Pending',
      _ => status[0].toUpperCase() + status.substring(1),
    };

Color bookingStatusColor(String status) => switch (status) {
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      'searching' => AppColors.warning,
      'assigned' || 'arriving' || 'started' => AppColors.primary,
      _ => AppColors.textSecondary,
    };

Future<void> showBookingDetailSheet(
  BuildContext context, {
  required BookingModel booking,
  required bool isAssistantView,
  VoidCallback? onPrimaryAction,
  String? primaryActionLabel,
  VoidCallback? onSecondaryAction,
  String? secondaryActionLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;
        return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + bottomSafe),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.category?.name ?? 'Booking',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: bookingStatusColor(booking.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          formatBookingStatusLabel(booking.status),
                          style: TextStyle(
                            color: bookingStatusColor(booking.status),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Booking #${booking.id.length > 8 ? booking.id.substring(booking.id.length - 8) : booking.id}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(Icons.schedule_rounded, 'Scheduled', DateFormat('EEE, MMM d • h:mm a').format(booking.scheduledAt)),
                  _detailRow(Icons.timer_outlined, 'Duration', '${booking.durationMin} minutes'),
                  _detailRow(Icons.store_mall_directory_outlined, 'Venue', booking.venueName),
                  _detailRow(Icons.place_outlined, 'Address', booking.addressFormatted),
                  _detailRow(Icons.location_on_outlined, 'Location', '${booking.lat.toStringAsFixed(5)}, ${booking.lng.toStringAsFixed(5)}'),
                  if (isAssistantView && booking.customer != null)
                    _detailRow(Icons.person_outline, 'Customer', booking.customer!['name'] as String? ?? 'Customer'),
                  if (!isAssistantView && booking.assistant != null) ...[
                    _detailRow(Icons.support_agent_outlined, 'Assistant', assistantSummaryLine(booking.assistant)),
                    if (assistantCodeFrom(booking.assistant) != null)
                      _detailRow(Icons.badge_outlined, 'Assistant ID', assistantCodeFrom(booking.assistant)!),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _feeLine('Service fee', booking.serviceFee),
                        _feeLine('Platform fee', booking.platformFee),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              '₹${booking.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (booking.isPaid)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Payment completed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (booking.statusHistory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Status timeline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 12),
                    StatusTimeline(currentStatus: booking.status),
                  ],
                  if (onPrimaryAction != null || onSecondaryAction != null) ...[
                    const SizedBox(height: 20),
                    if (onPrimaryAction != null && primaryActionLabel != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onPrimaryAction();
                          },
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(primaryActionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (onSecondaryAction != null && secondaryActionLabel != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onSecondaryAction();
                          },
                          child: Text(secondaryActionLabel!),
                        ),
                      ),
                    ],
                  ],
                  SizedBox(height: 24 + bottomSafe),
                ],
              ),
            ),
          ],
        ),
      );
      },
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _feeLine(String label, double amount) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
