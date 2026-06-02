import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';

const _presetAmounts = [100, 200, 500, 1000, 2000, 5000];
const _minAmount = 100;
const _maxAmount = 10000;

enum WalletTopUpMethod { upi, card }

class WalletAddMoneyScreen extends ConsumerStatefulWidget {
  final double currentBalance;

  const WalletAddMoneyScreen({super.key, required this.currentBalance});

  @override
  ConsumerState<WalletAddMoneyScreen> createState() => _WalletAddMoneyScreenState();
}

class _WalletAddMoneyScreenState extends ConsumerState<WalletAddMoneyScreen> {
  final _customAmountCtrl = TextEditingController();
  final _customFocus = FocusNode();
  int? _selectedPreset;
  WalletTopUpMethod _method = WalletTopUpMethod.upi;
  bool _paying = false;
  int _step = 0;

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  double? get _amount {
    if (_selectedPreset != null) return _selectedPreset!.toDouble();
    final parsed = double.tryParse(_customAmountCtrl.text.trim());
    return parsed;
  }

  bool get _isValidAmount {
    final a = _amount;
    return a != null && a >= _minAmount && a <= _maxAmount;
  }

  void _selectPreset(int value) {
    setState(() {
      _selectedPreset = value;
      _customAmountCtrl.clear();
    });
  }

  void _onCustomChanged(String value) {
    setState(() {
      _selectedPreset = null;
    });
  }

  void _goToReview() {
    if (!_isValidAmount) {
      final a = _amount;
      final msg = a == null || a < _minAmount
          ? 'Minimum amount is ₹$_minAmount'
          : 'Maximum amount is ₹$_maxAmount';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  Future<void> _pay() async {
    final amount = _amount;
    if (amount == null || !_isValidAmount) return;

    setState(() => _paying = true);
    final methodLabel = _method == WalletTopUpMethod.upi ? 'UPI' : 'Card';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentProcessingDialog(amount: amount, methodLabel: methodLabel),
    );

    if (confirmed != true || !mounted) {
      if (mounted) setState(() => _paying = false);
      return;
    }

    try {
      await ref.read(walletRepositoryProvider).addWalletMoney(
            amount,
            method: _method == WalletTopUpMethod.upi ? 'upi' : 'card',
          );
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      setState(() => _paying = false);
      await _showSuccess(amount);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        showAppErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _showSuccess(double amount) {
    final newBalance = ref.read(authProvider).user?.walletBalance ?? (widget.currentBalance + amount);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Money added!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)} added to your Liftoo wallet',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New balance', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('₹${newBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.navy)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Add money' : 'Review & pay'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _step == 0 ? _buildAmountStep() : _buildReviewStep(),
    );
  }

  Widget _buildAmountStep() {
    return KeyboardAwareScroll(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _balanceHint(),
          const SizedBox(height: 20),
          const Text('Select amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Between ₹$_minAmount and ₹$_maxAmount',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetAmounts.map((amt) {
              final selected = _selectedPreset == amt;
              return ChoiceChip(
                label: Text('₹$amt', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
                selected: selected,
                onSelected: (_) => _selectPreset(amt),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Or enter custom amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: _customAmountCtrl,
            focusNode: _customFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            scrollPadding: keyboardScrollPadding(context),
            onChanged: _onCustomChanged,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: 'e.g. 750',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Continue', onPressed: _isValidAmount ? _goToReview : null),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final amount = _amount ?? 0;
    return KeyboardAwareScroll(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiftooCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to add', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.navy)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance after top-up', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${(widget.currentBalance + amount).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _methodTile(
            method: WalletTopUpMethod.upi,
            title: 'UPI',
            subtitle: 'Google Pay, PhonePe, Paytm & more',
            icon: Icons.qr_code_2_rounded,
          ),
          const SizedBox(height: 10),
          _methodTile(
            method: WalletTopUpMethod.card,
            title: 'Debit / Credit card',
            subtitle: 'Visa, Mastercard, RuPay',
            icon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: AppColors.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Secure payment. Money is added instantly to your wallet after confirmation.',
                    style: TextStyle(fontSize: 12, color: AppColors.charcoal.withValues(alpha: 0.85), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Pay ₹${amount.toStringAsFixed(0)}',
            isLoading: _paying,
            onPressed: _paying ? null : _pay,
          ),
        ],
      ),
    );
  }

  Widget _balanceHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, Color(0xFF002A5C)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
              Text(
                '₹${widget.currentBalance.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required WalletTopUpMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _method == method;
    return LiftooCard(
      onTap: () => setState(() => _method = method),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _PaymentProcessingDialog extends StatefulWidget {
  final double amount;
  final String methodLabel;

  const _PaymentProcessingDialog({required this.amount, required this.methodLabel});

  @override
  State<_PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<_PaymentProcessingDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Processing ${widget.methodLabel} payment', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '₹${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            const Text('Please wait…', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
