import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/network_errors.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';

class RequestPayoutSheet extends StatefulWidget {
  final double available;
  final String? bankAccount;
  final String? ifscCode;
  final Future<void> Function(double amount) onSubmit;

  const RequestPayoutSheet({
    super.key,
    required this.available,
    required this.onSubmit,
    this.bankAccount,
    this.ifscCode,
  });

  static Future<void> show(
    BuildContext context, {
    required double available,
    required Future<void> Function(double amount) onSubmit,
    String? bankAccount,
    String? ifscCode,
    bool bankVerified = true,
  }) {
    if (!bankVerified || bankAccount == null) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _BankSetupSheet(
          onSetup: () {
            Navigator.pop(ctx);
            context.push('/assistant/verification');
          },
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestPayoutSheet(
        available: available,
        bankAccount: bankAccount,
        ifscCode: ifscCode,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RequestPayoutSheet> createState() => _RequestPayoutSheetState();
}

class _RequestPayoutSheetState extends State<RequestPayoutSheet> {
  late final TextEditingController _amountCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.available.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  Future<void> _submit() async {
    final amount = _parsedAmount;
    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > widget.available) {
      setState(() => _error = 'Maximum available is ₹${widget.available.toStringAsFixed(0)}');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit(amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = NetworkErrors.userMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Withdraw earnings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.charcoal),
                ),
                const SizedBox(height: 6),
                Text(
                  'Transfer your available balance to your verified bank account.',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy, Color(0xFF002A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available to withdraw',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${widget.available.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _amountCtrl.text = widget.available.toStringAsFixed(0);
                          setState(() => _error = null);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Withdraw all', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payout account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              widget.bankAccount ?? 'Not linked',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (widget.ifscCode != null)
                              Text('IFSC ${widget.ifscCode}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Withdrawal amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.charcoal),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 8),
                Text(
                  'Payouts are reviewed by admin and usually processed within 2–3 business days.',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Request withdrawal',
                  isLoading: _loading,
                  onPressed: _loading ? null : _submit,
                  backgroundColor: AppColors.navy,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankSetupSheet extends StatelessWidget {
  final VoidCallback onSetup;

  const _BankSetupSheet({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_outlined, color: AppColors.warning, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add bank details first',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete bank verification in your profile before requesting a payout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              GradientButton(label: 'Complete verification', onPressed: onSetup),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
            ],
          ),
        ),
      ),
    );
  }
}
