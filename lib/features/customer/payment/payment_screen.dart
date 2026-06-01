import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../booking/booking_flow.dart';
import '../booking/service_time_summary_dialog.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'wallet';
  bool _loading = false;
  BookingModel? _booking;
  double _walletBalance = 0;
  final _promoCtrl = TextEditingController();
  double _discount = 0;
  String? _appliedPromo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
      final w = await ref.read(walletRepositoryProvider).getWallet();
      if (mounted) {
        setState(() {
          _booking = b;
          _walletBalance = (w['balance'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _applyPromo() async {
    final b = _booking;
    if (b == null || _promoCtrl.text.trim().isEmpty) return;
    try {
      final result = await ref.read(promosRepositoryProvider).applyToBooking(b.id, _promoCtrl.text.trim());
      final discount = (result['discountAmount'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        setState(() {
          _discount = discount;
          _appliedPromo = _promoCtrl.text.trim().toUpperCase();
        });
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo applied — saved ₹${discount.toStringAsFixed(0)}')),
        );
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    }
  }

  double get _payAmount => _booking?.totalAmount ?? 0;

  Future<void> _pay() async {
    final b = _booking;
    if (b == null) return;
    if (_method == 'wallet' && _walletBalance < _payAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance. Please choose UPI or Cash.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(bookingRepositoryProvider).payBooking(widget.bookingId, _method);
      if (!mounted) return;

      final paidBooking = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
      if (!mounted) return;
      await showServiceTimeSummary(context, paidBooking);
      if (!mounted) return;

      if (result.nextStep == 'rate_app') {
        openAppReview(context, widget.bookingId);
      } else {
        openServiceReview(context, widget.bookingId);
      }

      ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Payment')),
      body: b == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : KeyboardAwareScroll(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.category?.name ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(b.venueName, style: const TextStyle(color: AppColors.textSecondary)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total amount', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('₹${_payAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.primary)),
                          ],
                        ),
                        if (_discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Promo $_appliedPromo applied (−₹${_discount.toStringAsFixed(0)})', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                          ),
                        const SizedBox(height: 8),
                        Text('Wallet balance: ₹${_walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          scrollPadding: keyboardScrollPadding(context),
                          decoration: const InputDecoration(hintText: 'Promo code'),
                        ),
                      ),
                      TextButton(onPressed: _applyPromo, child: const Text('Apply')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...['wallet', 'upi', 'cash'].map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LiftooCard(
                          onTap: () => setState(() => _method = m),
                          child: Row(
                            children: [
                              Icon(_method == m ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text(m.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 24),
                  GradientButton(label: 'Pay ₹${_payAmount.toStringAsFixed(0)}', isLoading: _loading, onPressed: _pay),
                ],
              ),
            ),
    );
  }
}
