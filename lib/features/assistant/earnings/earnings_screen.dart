import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/liftoo_card.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ref.read(walletRepositoryProvider).getEarnings();
    if (mounted) setState(() => _data = d);
  }

  Future<void> _requestPayout() async {
    final balance = await ref.read(payoutsRepositoryProvider).getBalance();
    final available = (balance['available'] as num?)?.toDouble() ?? 0;
    if (available <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No balance available for payout')));
      }
      return;
    }
    final ctrl = TextEditingController(text: available.toStringAsFixed(0));
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request payout'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Amount (max ₹${available.toStringAsFixed(0)})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(ctrl.text) ?? 0;
    if (amount <= 0 || amount > available) return;
    try {
      await ref.read(payoutsRepositoryProvider).requestPayout(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request submitted')));
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _data?['history'] as List<dynamic>? ?? [];
    final today = (_data?['todayEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final week = (_data?['weeklyEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final total = (_data?['totalEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final jobs = _data?['totalJobs'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.charcoal.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Total earnings', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '₹$total',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroChip('Today', '₹$today'),
                      const SizedBox(width: 10),
                      _heroChip('This week', '₹$week'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LiftooCard(
              onTap: _requestPayout,
              child: const Row(
                children: [
                  Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(child: Text('Request payout', style: TextStyle(fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LiftooCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$jobs jobs completed', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const Text('Keep going — more bookings mean more earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (history.isEmpty)
              LiftooCard(
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('No earnings yet', style: TextStyle(color: AppColors.textSecondary))),
                  ],
                ),
              )
            else
              ...history.map((e) {
                final m = e as Map<String, dynamic>;
                final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                final desc = m['description'] as String? ?? 'Earning';
                final date = m['createdAt'] as String? ?? m['date'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LiftooCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payments_outlined, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(desc, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (date != null)
                                Text(
                                  _formatDate(date),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '+₹${amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
