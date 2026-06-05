import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_datetime.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../shared/assistant_home_refresh_provider.dart';
import 'widgets/request_payout_sheet.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  Map<String, dynamic>? _earnings;
  double _available = 0;
  List<dynamic> _payoutRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ref.read(walletRepositoryProvider).getEarnings(),
        ref.read(payoutsRepositoryProvider).getBalance(),
        ref.read(payoutsRepositoryProvider).getRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _earnings = results[0] as Map<String, dynamic>;
        _available = ((results[1] as Map<String, dynamic>)['available'] as num?)?.toDouble() ?? 0;
        _payoutRequests = results[2] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _payoutDetails =>
      _earnings?['payoutDetails'] as Map<String, dynamic>?;

  Future<void> _requestPayout() async {
    if (_available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balance available for withdrawal yet')),
      );
      return;
    }

    final bankAccount = _payoutDetails?['bankAccount'] as String?;
    final ifscCode = _payoutDetails?['ifscCode'] as String?;
    final bankVerified = bankAccount != null && bankAccount.isNotEmpty;

    await RequestPayoutSheet.show(
      context,
      available: _available,
      bankAccount: bankAccount,
      ifscCode: ifscCode,
      bankVerified: bankVerified,
      onSubmit: (amount) async {
        await ref.read(payoutsRepositoryProvider).requestPayout(amount);
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted')),
        );
        await _load();
        refreshAssistantHome(ref);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(assistantHomeRefreshProvider, (_, __) => _load());

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final history = _earnings?['history'] as List<dynamic>? ?? [];
    final today = (_earnings?['todayEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final week = (_earnings?['weeklyEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final total = (_earnings?['totalEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final jobs = _earnings?['totalJobs'] ?? 0;
    final pendingPayout = _payoutRequests.where((r) {
      final status = (r as Map<String, dynamic>)['status'] as String?;
      return status == 'pending' || status == 'approved';
    }).toList();

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
            _buildTotalHero(total, today, week),
            const SizedBox(height: 16),
            _buildWithdrawCard(pendingPayout),
            const SizedBox(height: 14),
            _buildJobsCard(jobs),
            if (_payoutRequests.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader('Withdrawal requests'),
              const SizedBox(height: 10),
              ..._payoutRequests.take(5).map(_payoutRequestTile),
            ],
            const SizedBox(height: 24),
            _sectionHeader('Earning history'),
            const SizedBox(height: 10),
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
              ...history.map(_earningTile),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
  }

  Widget _buildTotalHero(String total, String today, String week) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF002A5C)],
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
    );
  }

  Widget _buildWithdrawCard(List<dynamic> pendingPayout) {
    final bankAccount = _payoutDetails?['bankAccount'] as String?;
    final hasPending = pendingPayout.isNotEmpty;
    final pendingAmount = hasPending
        ? (pendingPayout.first as Map<String, dynamic>)['amount'] as num?
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_outlined, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available to withdraw', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(
                      '₹${_available.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.charcoal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPending) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '₹${pendingAmount?.toStringAsFixed(0) ?? '—'} withdrawal is being processed',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (bankAccount != null) ...[
            const SizedBox(height: 12),
            Text(
              'Payout account: $bankAccount',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/assistant/verification'),
              child: Text(
                'Add bank details to enable withdrawals →',
                style: TextStyle(color: AppColors.primary.withValues(alpha: 0.95), fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GradientButton(
            label: _available > 0 ? 'Withdraw earnings' : 'No balance to withdraw',
            icon: Icons.arrow_outward_rounded,
            backgroundColor: AppColors.navy,
            onPressed: _available > 0 && !hasPending ? _requestPayout : null,
          ),
          if (hasPending)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'You can request another withdrawal after the current one is processed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobsCard(int jobs) {
    return LiftooCard(
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
    );
  }

  Widget _payoutRequestTile(dynamic raw) {
    final m = raw as Map<String, dynamic>;
    final amount = (m['amount'] as num?)?.toDouble() ?? 0;
    final status = m['status'] as String? ?? 'pending';
    final date = m['createdAt'] as String?;
    final color = switch (status) {
      'paid' => AppColors.success,
      'rejected' => AppColors.error,
      'approved' => AppColors.primary,
      _ => AppColors.warning,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiftooCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.account_balance_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Withdrawal request', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (date != null)
                    Text(_formatDate(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningTile(dynamic raw) {
    final m = raw as Map<String, dynamic>;
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
                    Text(_formatDate(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    final formatted = formatAppDateTimeIso(raw, pattern: 'MMM d, h:mm a');
    return formatted.isEmpty ? raw : formatted;
  }
}
