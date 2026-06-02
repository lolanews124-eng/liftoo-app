import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/models/booking_model.dart';

Future<String?> showRejectReasonDialog(BuildContext context, {String? venueName}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _RejectReasonDialog(venueName: venueName),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  final String? venueName;

  const _RejectReasonDialog({this.venueName});

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < 3) {
      setState(() => _error = 'Please enter at least 3 characters');
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: keyboardInsetPadding(context, base: const EdgeInsets.fromLTRB(24, 28, 24, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reject request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              widget.venueName != null
                  ? 'Why can you not take the booking at ${widget.venueName}?'
                  : 'Why can you not take this booking?',
              style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 200,
              scrollPadding: keyboardScrollPadding(context),
              decoration: InputDecoration(
                hintText: 'e.g. Too far, already busy…',
                errorText: _error,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showBookingRequestPopup(
  BuildContext context, {
  required BookingModel booking,
  required VoidCallback onAccept,
  required Future<void> Function(String reason) onReject,
}) {
  return showGeneralDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'Booking request',
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => _BookingRequestPopup(
      booking: booking,
      onAccept: onAccept,
      onReject: onReject,
    ),
    transitionBuilder: (ctx, anim, _, child) => Transform.scale(
      scale: 0.92 + (anim.value * 0.08),
      child: Opacity(opacity: anim.value, child: child),
    ),
  );
}

class _BookingRequestPopup extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final Future<void> Function(String reason) onReject;

  const _BookingRequestPopup({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  Future<void> _reject(BuildContext context) async {
    Navigator.pop(context);
    final reason = await showRejectReasonDialog(context, venueName: booking.venueName);
    if (reason != null) await onReject(reason);
  }

  @override
  Widget build(BuildContext context) {
    final earn = (booking.serviceFee * 0.8).toStringAsFixed(0);
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('New booking request', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    booking.category?.name ?? 'Shopping assistance',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.storefront_outlined, booking.venueName),
                  _infoRow(Icons.place_outlined, booking.addressFormatted),
                  _infoRow(Icons.timer_outlined, '${booking.durationMin} minutes'),
                  if (booking.distanceKm != null)
                    _infoRow(Icons.near_me_outlined, '${booking.distanceKm} km away'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'You earn ~₹$earn',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            onAccept();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
