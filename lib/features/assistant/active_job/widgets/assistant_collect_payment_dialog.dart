import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/error_snackbar.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/booking_model.dart';

Future<void> showAssistantCollectPaymentDialog(
  BuildContext context, {
  required WidgetRef ref,
  required BookingModel booking,
  double? assistantEarning,
  String? paymentConfirmOtp,
}) async {
  final earning = assistantEarning ?? booking.assistantEarningAmount ?? booking.serviceFee * 0.8;
  final companyShare = booking.companyShareAmount ?? (booking.totalAmount - earning);
  final otp = paymentConfirmOtp ?? booking.paymentConfirmOtp ?? '----';

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AssistantCollectPaymentDialog(
      ref: ref,
      booking: booking,
      assistantEarning: earning,
      companyShare: companyShare,
      paymentOtp: otp,
    ),
  );
}

class _AssistantCollectPaymentDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final BookingModel booking;
  final double assistantEarning;
  final double companyShare;
  final String paymentOtp;

  const _AssistantCollectPaymentDialog({
    required this.ref,
    required this.booking,
    required this.assistantEarning,
    required this.companyShare,
    required this.paymentOtp,
  });

  @override
  ConsumerState<_AssistantCollectPaymentDialog> createState() => _AssistantCollectPaymentDialogState();
}

class _AssistantCollectPaymentDialogState extends ConsumerState<_AssistantCollectPaymentDialog> {
  bool _loading = false;
  bool _cashMarked = false;

  Future<void> _markCashReceived() async {
    setState(() => _loading = true);
    try {
      await ref.read(bookingRepositoryProvider).markCashCollected(widget.booking.id);
      if (mounted) setState(() => _cashMarked = true);
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.booking.totalAmount;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.success),
          SizedBox(width: 10),
          Expanded(child: Text('Collect payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service completed. Customer must pay in the Liftoo app.', style: TextStyle(height: 1.4)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer pays: ₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Your earning: ₹${widget.assistantEarning.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                  Text(
                    'Company share (cash): ₹${widget.companyShare.toStringAsFixed(0)} from settlement wallet',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment OTP (customer enters in app)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.paymentOtp,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.paymentOtp));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP copied')));
                    },
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'For cash: tap below after receiving money, then ask customer to confirm with this OTP.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            if (_cashMarked) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Cash received recorded', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_cashMarked)
          OutlinedButton(
            onPressed: _loading ? null : _markCashReceived,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Cash received'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
