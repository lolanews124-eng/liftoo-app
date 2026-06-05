import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../shared/assistant_online_confirm.dart';
import '../requests/assistant_booking_request_flow.dart';
import '../requests/booking_request_popup.dart';
import '../shared/assistant_online_service.dart';
import '../shared/assistant_home_refresh_provider.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class AssistantDashboardScreen extends ConsumerStatefulWidget {
  const AssistantDashboardScreen({super.key});

  @override
  ConsumerState<AssistantDashboardScreen> createState() => _AssistantDashboardScreenState();
}

class _AssistantDashboardScreenState extends ConsumerState<AssistantDashboardScreen> {
  Map<String, dynamic>? _earnings;
  BookingModel? _activeJob;
  List<BookingModel> _nearbyRequests = [];
  bool _loading = true;
  void Function(dynamic)? _bookingUpdatedHandler;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachBookingListener());
  }

  @override
  void dispose() {
    _detachBookingListener();
    super.dispose();
  }

  bool _initialized = false;

  void _attachBookingListener() {
    _detachBookingListener();
    _bookingUpdatedHandler = (_) => _load(silent: true);
    ref.read(socketServiceProvider).on('booking:updated', _bookingUpdatedHandler!);
  }

  void _detachBookingListener() {
    if (_bookingUpdatedHandler != null) {
      ref.read(socketServiceProvider).off('booking:updated', _bookingUpdatedHandler);
      _bookingUpdatedHandler = null;
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && !_initialized) setState(() => _loading = true);
    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final results = await Future.wait([
        ref.read(walletRepositoryProvider).getEarnings(),
        bookingRepo.getActiveJob(),
        bookingRepo.getNearbyRequests(),
      ]);
      if (mounted) {
        setState(() {
          _earnings = results[0] as Map<String, dynamic>;
          _activeJob = results[1] as BookingModel?;
          _nearbyRequests = results[2] as List<BookingModel>;
          _loading = false;
          _initialized = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOnline(bool targetOnline) async {
    final ok = await confirmAssistantOnlineChange(context, targetOnline);
    if (!ok || !mounted) return;
    HapticFeedback.lightImpact();
    try {
      await setAssistantOnline(ref, targetOnline);
      if (targetOnline) await _load(silent: true);
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    }
  }

  Future<void> _openRequest(BookingModel booking) async {
    await presentAssistantBookingRequest(ref, booking: booking);
    await _load(silent: true);
  }

  Future<void> _acceptRequest(BookingModel booking) async {
    HapticFeedback.mediumImpact();
    try {
      final accepted = await ref.read(bookingRepositoryProvider).acceptBooking(booking.id);
      if (mounted) {
        await context.push('/assistant/active/${accepted.id}');
        await _load(silent: true);
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
      await _load(silent: true);
    }
  }

  Future<void> _rejectRequest(BookingModel booking) async {
    final reason = await showRejectReasonDialog(context, venueName: booking.venueName);
    if (reason == null || !mounted) return;
    HapticFeedback.lightImpact();
    await ref.read(bookingRepositoryProvider).rejectBooking(booking.id, reason: reason);
    await _load(silent: true);
  }

  String _statusLabel(BookingModel job) {
    if (job.isPaymentPending) return 'Payment pending';
    return switch (job.status) {
      'searching' => 'Searching',
      'assigned' => 'Assigned',
      'arriving' => 'On the way',
      'started' => 'In progress',
      'completed' => 'Completed',
      _ => job.status.replaceAll('_', ' '),
    };
  }

  Color _statusColor(BookingModel job) {
    if (job.isPaymentPending) return AppColors.warning;
    return switch (job.status) {
      'arriving' => AppColors.primary,
      'started' => AppColors.success,
      'assigned' => AppColors.warning,
      'completed' => AppColors.success,
      _ => AppColors.textSecondary,
    };
  }

  List<Map<String, dynamic>> get _recentEarnings {
    final history = _earnings?['history'] as List<dynamic>? ?? [];
    return history.take(3).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(assistantHomeRefreshProvider, (_, __) {
      _load(silent: true);
      _attachBookingListener();
    });

    final user = ref.watch(authProvider).user;
    final isOnline = user?.isOnline ?? false;
    final ap = user?.assistantProfile;
    final completion = ap?.profileCompletion ?? 0;
    final firstName = (user?.name ?? 'Assistant').split(' ').first;
    final todayEarnings = (_earnings?['todayEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final weekEarnings = (_earnings?['weeklyEarnings'] as num?)?.toStringAsFixed(0) ?? '0';
    final totalEarnings = (_earnings?['totalEarnings'] as num?)?.toStringAsFixed(0) ?? '0';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const _DashboardSkeleton()
            : Column(
                children: [
                  ColoredBox(
                    color: AppColors.surface,
                    child: _buildHeader(firstName, user, ap),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (ap?.adminVerified != true)
                            SliverToBoxAdapter(child: _buildVerificationBanner(ap?.assistantCode)),
                          SliverToBoxAdapter(child: _buildOnlineBanner(isOnline)),
                          SliverToBoxAdapter(child: _buildEarningsHero(todayEarnings, weekEarnings, totalEarnings)),
                          SliverToBoxAdapter(child: _buildStatsRow(ap)),
                          if (_activeJob != null) SliverToBoxAdapter(child: _buildActiveJobSection(_activeJob!)),
                          SliverToBoxAdapter(child: _buildRequestsSection(isOnline)),
                          if (_recentEarnings.isNotEmpty) SliverToBoxAdapter(child: _buildRecentActivity()),
                          if (completion < 100) SliverToBoxAdapter(child: _buildProfileNudge(completion)),
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(String firstName, UserModel? user, AssistantProfileModel? ap) {
    final initial = (user?.name ?? 'A')[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.85), AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $firstName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Assistant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                    ),
                    if (ap != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                      const SizedBox(width: 2),
                      Text(ap.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(' • ${ap.totalJobs} jobs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _headerIcon(Icons.notifications_outlined, () => context.push('/notifications')),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 22, color: AppColors.charcoal),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(String? assistantCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Awaiting admin approval', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assistantCode != null
                  ? 'Your ID $assistantCode is registered. Complete KYC and wait for admin verification before going online.'
                  : 'Complete KYC and wait for admin verification before you can receive jobs.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.push('/assistant/verification'),
              child: const Text('Complete verification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBanner(bool isOnline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isOnline
              ? LinearGradient(
                  colors: [AppColors.success.withValues(alpha: 0.12), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isOnline ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isOnline ? AppColors.success.withValues(alpha: 0.35) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? AppColors.success : Colors.black).withValues(alpha: isOnline ? 0.08 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isOnline ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                if (isOnline)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                    ),
                  ),
                Icon(
                  isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                  color: isOnline ? AppColors.success : AppColors.textSecondary,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'You are online' : 'You are offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: isOnline ? AppColors.success : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline
                        ? 'Receiving nearby booking requests'
                        : 'Turn on to start accepting jobs',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch.adaptive(
                value: isOnline,
                onChanged: _toggleOnline,
                activeTrackColor: AppColors.success,
                activeThumbColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHero(String today, String week, String total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, Color(0xFF002A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.charcoal.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 10)),
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
                  child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text("Today's earnings", style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/assistant/earnings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '₹$today',
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _earningsChip('This week', '₹$week'),
                const SizedBox(width: 10),
                _earningsChip('All time', '₹$total'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsChip(String label, String value) {
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
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AssistantProfileModel? ap) {
    final todayJobs = _earnings?['todayJobs'] ?? 0;
    final totalJobs = _earnings?['totalJobs'] ?? ap?.totalJobs ?? 0;
    final rating = ap?.rating.toStringAsFixed(1) ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _statCell('Today', '$todayJobs', 'jobs', Icons.today_outlined),
              _verticalDivider(),
              _statCell('Completed', '$totalJobs', 'total', Icons.task_alt_outlined),
              _verticalDivider(),
              _statCell('Rating', rating, 'stars', Icons.star_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, color: Colors.grey.shade200);

  Widget _statCell(String label, String value, String sub, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.85)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActiveJobSection(BookingModel job) {
    final customerName = job.customer?['name'] as String? ?? 'Customer';
    final earn = (job.serviceFee * 0.8).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            job.isPaymentPending ? 'Awaiting payment' : 'Active job',
            trailing: _statusBadge(_statusLabel(job), _statusColor(job)),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () async {
                await context.push('/assistant/active/${job.id}');
                if (mounted) await _load(silent: true);
              },
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 16,
                            bottom: 12,
                            child: Icon(Icons.map_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    job.venueName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.category?.name ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(customerName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${job.durationMin} min • Earn ₹$earn', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  await context.push('/assistant/active/${job.id}');
                                  if (mounted) await _load(silent: true);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: job.isPaymentPending ? AppColors.warning : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  job.isPaymentPending ? 'Collect' : 'Open',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(bool isOnline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Incoming requests',
            trailing: _nearbyRequests.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_nearbyRequests.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  )
                : TextButton(onPressed: () => context.push('/assistant/nearby-requests'), child: const Text('View all')),
          ),
          const SizedBox(height: 12),
          if (!isOnline)
            _emptyPanel(
              icon: Icons.wifi_off_rounded,
              title: 'Go online first',
              subtitle: 'Turn on your availability to see booking requests in your area.',
            )
          else if (_nearbyRequests.isEmpty)
            _emptyPanel(
              icon: Icons.radar_outlined,
              title: 'No requests yet',
              subtitle: 'Stay online — new bookings will appear here automatically.',
            )
          else
            ..._nearbyRequests.take(3).map(_requestCard),
        ],
      ),
    );
  }

  Widget _requestCard(BookingModel b) {
    final earn = (b.serviceFee * 0.8).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary.withValues(alpha: 0.9), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.category?.name ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(b.venueName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹$earn', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 16)),
                  Text(DateFormat('h:mm a').format(b.scheduledAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metaChip(Icons.timer_outlined, '${b.durationMin} min'),
              const SizedBox(width: 8),
              _metaChip(Icons.person_outline, b.customer?['name'] as String? ?? 'Customer'),
              if (b.distanceKm != null) ...[
                const SizedBox(width: 8),
                _metaChip(Icons.place_outlined, '${b.distanceKm} km'),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () => _rejectRequest(b),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Reject', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () => _openRequest(b),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Received', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () => _acceptRequest(b),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recent earnings', trailing: TextButton(onPressed: () => context.go('/assistant/earnings'), child: const Text('See all'))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: _recentEarnings.asMap().entries.map((entry) {
                final m = entry.value;
                final isLast = entry.key == _recentEarnings.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.south_west, color: AppColors.success, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(m['description'] as String? ?? 'Earning', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          Text(
                            '+₹${(m['amount'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNudge(int completion) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/assistant/verification'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warning.withValues(alpha: 0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user_outlined, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Complete your profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: completion / 100, minHeight: 6, backgroundColor: Colors.white, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$completion%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Widget _emptyPanel({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        Row(
          children: [
            SkeletonBox(width: 48, height: 48, radius: 14),
            SizedBox(width: 14),
            Expanded(child: SkeletonBox(height: 44, radius: 12)),
          ],
        ),
        SizedBox(height: 20),
        SkeletonBox(height: 92, radius: 22),
        SizedBox(height: 16),
        SkeletonBox(height: 160, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(height: 88, radius: 20),
        SizedBox(height: 20),
        SkeletonBox(height: 200, radius: 22),
      ],
    );
  }
}
