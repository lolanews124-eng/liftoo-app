import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../booking/booking_flow.dart';
import '../booking/service_time_summary_dialog.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/review_models.dart';
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
  final _cashOtpCtrl = TextEditingController();
  double _discount = 0;
  String? _appliedPromo;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final b = _booking;
      if (b != null && _method == 'cash' && !b.isCashAwaitingCustomerConfirm) {
        _load();
      }
    });
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

  Future<void> _afterPaymentSuccess(dynamic result) async {
    if (!mounted) return;
    final paidBooking = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
    if (!mounted) return;
    await showServiceTimeSummary(context, paidBooking);
    if (!mounted) return;

    final nextStep = result is PaymentResultModel ? result.nextStep : paidBooking.nextStep;
    if (nextStep == 'rate_app') {
      openAppReview(context, widget.bookingId);
    } else {
      openServiceReview(context, widget.bookingId);
    }
    ref.read(authProvider.notifier).refreshUser();
  }

  Future<void> _pay() async {
    final b = _booking;
    if (b == null) return;

    if (_method == 'cash') {
      if (!b.isCashAwaitingCustomerConfirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Give cash to your assistant, then ask them to tap "Cash received" in their app before you enter OTP.'),
          ),
        );
        return;
      }
      final otp = _cashOtpCtrl.text.trim();
      if (otp.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 4-digit OTP from assistant')));
        return;
      }
      setState(() => _loading = true);
      try {
        final result = await ref.read(bookingRepositoryProvider).confirmCashPayment(widget.bookingId, otp);
        await _afterPaymentSuccess(result);
      } catch (e) {
        if (mounted) showAppErrorSnackBar(context, e);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (_method == 'wallet' && _walletBalance < _payAmount) {
      final added = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Low wallet balance'),
          content: Text(
            'You need ₹${_payAmount.toStringAsFixed(0)} but have ₹${_walletBalance.toStringAsFixed(0)}. Add money to your wallet?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add money'),
            ),
          ],
        ),
      );
      if (added == true && mounted) {
        final toppedUp = await context.push<bool>('/customer/wallet/add', extra: _walletBalance);
        if (toppedUp == true && mounted) await _load();
      }
      if (!mounted) return;
      if (_walletBalance < _payAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still insufficient balance. Add more or pay via UPI/Cash.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final result = await ref.read(bookingRepositoryProvider).payBooking(widget.bookingId, _method);
      await _afterPaymentSuccess(result);
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _promoCtrl.dispose();
    _cashOtpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    final assistantName = b?.assistant?['name'] ?? 'Assistant';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Pay for service')),
      body: b == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: KeyboardAwareScroll(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Service is complete. Pay now to close this booking.',
                            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.category?.name ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(b.venueName, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Assistant: $assistantName', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const Divider(height: 24),
                        _feeRow('Service fee', b.serviceFee),
                        _feeRow('Platform fee', b.platformFee),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total to pay', style: TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              '₹${_payAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (_discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Promo $_appliedPromo applied (−₹${_discount.toStringAsFixed(0)})',
                              style: const TextStyle(fontSize: 12, color: AppColors.success),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text('Wallet balance: ₹${_walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  _methodTile('wallet', 'Liftoo Wallet', 'Instant • Recommended'),
                  _methodTile('upi', 'UPI', 'Google Pay, PhonePe, Paytm'),
                  _methodTile('cash', 'Cash', 'Pay assistant in person'),
                  if (_method == 'cash') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.isCashAwaitingCustomerConfirm
                                ? 'Assistant confirmed cash. Enter OTP to finish.'
                                : 'Step 1: Pay ₹${_payAmount.toStringAsFixed(0)} in cash to $assistantName',
                            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                          ),
                          if (!b.isCashAwaitingCustomerConfirm) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Step 2: Assistant taps "Cash received" in their app',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Text(
                              'Step 3: Enter the 4-digit OTP shown on assistant phone',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                          if (b.isCashAwaitingCustomerConfirm) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cashOtpCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Payment OTP',
                                hintText: '4 digits from assistant',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    label: _method == 'cash'
                        ? (b.isCashAwaitingCustomerConfirm ? 'Confirm cash payment' : 'Waiting for assistant…')
                        : 'Pay ₹${_payAmount.toStringAsFixed(0)}',
                    isLoading: _loading,
                    onPressed: _method == 'cash' && !b.isCashAwaitingCustomerConfirm ? null : _pay,
                  ),
                  if (_method == 'cash' && !b.isCashAwaitingCustomerConfirm) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh status'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ),
    );
  }

  Widget _feeRow(String label, double amount) {
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

  Widget _methodTile(String id, String title, String subtitle) {
    final selected = _method == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiftooCard(
        onTap: () => setState(() => _method = id),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
