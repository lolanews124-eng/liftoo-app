import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../shared/models/booking_model.dart';
import '../../booking/shared/booking_realtime.dart';
import '../booking/booking_flow.dart';
import '../home/home_sheets.dart';
import '../../../shared/widgets/live_tracking_map.dart';
import '../../../shared/widgets/assistant_info.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'cancel_booking_dialog.dart';
import 'service_timer_card.dart';
import '../../../shared/widgets/status_timeline.dart';

class LiveBookingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const LiveBookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<LiveBookingScreen> createState() => _LiveBookingScreenState();
}

class _LiveBookingScreenState extends ConsumerState<LiveBookingScreen> {
  BookingModel? _booking;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenBookingUpdates(ref, widget.bookingId, (booking) {
        if (!mounted) return;
        setState(() => _booking = booking);
        _handlePostLoadRedirect(booking);
      });
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      final b = _booking;
      if (b == null) return;
      if (b.status == 'cancelled') return;
      if (b.status == 'completed' && !b.isPaymentPending) return;
      if (!b.isActive && b.status != 'completed') return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    stopBookingUpdates(ref);
    super.dispose();
  }

  bool _redirected = false;

  void _handlePostLoadRedirect(BookingModel b) {
    if (_redirected) return;
    if (b.status == 'cancelled') {
      _redirected = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(b.statusHistory.isNotEmpty ? (b.statusHistory.last.note ?? 'Booking cancelled') : 'Booking cancelled')),
      );
      context.go('/customer/bookings');
      return;
    }
    if (b.isPaymentPending) {
      _redirected = true;
      navigateBookingNextStep(context, b, overrideStep: 'pay');
    } else if (b.status == 'completed' && b.isPaid && !b.hasServiceReview) {
      _redirected = true;
      navigateBookingNextStep(context, b, overrideStep: 'rate_service');
    }
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final b = await ref
          .read(bookingRepositoryProvider)
          .getBooking(widget.bookingId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      var active = b;
      if (b.status == 'pending') {
        try {
          active = await ref.read(bookingRepositoryProvider).confirmBooking(b.id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _booking = active;
        _error = null;
      });
      _handlePostLoadRedirect(active);
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = NetworkErrors.userMessage(e));
    }
  }

  Future<void> _cancel() async {
    final b = _booking;
    final result = await showCancelBookingDialog(context, venueName: b?.venueName);
    if (result == null || !mounted) return;
    await ref.read(bookingRepositoryProvider).cancelBooking(
          widget.bookingId,
          reason: result.reason,
          note: result.note,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      context.go('/customer/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live booking')),
        body: NetworkErrorState(
          message: _error,
          offline: _error == NetworkErrors.noInternet,
          onRetry: _load,
        ),
      );
    }

    final b = _booking;
    if (b == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final canCancel = b.isActive && b.status != 'started';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live booking'),
        actions: [
          if (b.assistant != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push('/chat/${b.id}'),
            ),
          if (canCancel)
            TextButton(onPressed: _cancel, child: const Text('Cancel', style: TextStyle(color: AppColors.error))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (b.tracking != null && ['assigned', 'arriving', 'started'].contains(b.status)) ...[
              LiveTrackingMap(tracking: b.tracking!),
              const SizedBox(height: 16),
            ],
            LiftooCard(
              child: Column(
                children: [
                  Text(_statusLabel(b.status), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  StatusTimeline(currentStatus: b.status == 'pending' ? 'searching' : b.status),
                ],
              ),
            ),
            if (b.assistant != null) ...[
              const SizedBox(height: 16),
              _assistantCard(b),
            ],
            if (b.status == 'searching') ...[
              const SizedBox(height: 16),
              LiftooCard(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.searchAvailability?.message ?? 'Searching for verified assistants near you…',
                        style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (b.status == 'arriving' || (b.status == 'assigned' && b.serviceOtp != null)) ...[
              const SizedBox(height: 16),
              LiftooCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Service OTP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        b.serviceOtp ?? '—',
                        style: TextStyle(
                          fontSize: b.serviceOtp != null ? 32 : 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: b.serviceOtp != null ? 8 : 0,
                          color: b.serviceOtp != null ? AppColors.charcoal : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (b.serviceOtp == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'OTP will appear once your assistant accepts the booking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Share this OTP with your assistant when they arrive. Service timer starts only after they verify it.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warning.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Waiting for assistant to verify OTP…',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (b.status == 'started') ...[
              const SizedBox(height: 16),
              ServiceTimerCard(booking: b),
            ],
            if (b.isPaymentPending) ...[
              const SizedBox(height: 16),
              GradientButton(
                label: 'Proceed to Payment',
                onPressed: () => context.push('/customer/payment/${b.id}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _assistantCard(BookingModel b) {
    final profile = b.assistant!['assistantProfile'] as Map<String, dynamic>?;
    final rating = (profile?['rating'] as num?)?.toDouble() ?? 4.9;
    final totalJobs = (profile?['totalJobs'] as num?)?.toInt() ?? 0;
    final assistantPhone = b.assistant?['phone'] as String? ?? '9876543211';

    return LiftooCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              (b.assistant!['name'] as String? ?? 'A')[0],
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assistantNameFrom(b.assistant), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                AssistantIdBadge(assistant: b.assistant, compact: true),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.work_outline, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('$totalJobs jobs', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                if (b.tracking?.etaMinutes != null && b.status == 'arriving')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'ETA ~${b.tracking!.etaMinutes} min · ${b.tracking!.distanceKm ?? ''} km away',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (b.status == 'arriving')
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('On the way to you', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => callAssistant(assistantPhone),
            icon: const Icon(Icons.phone, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'searching' => 'Searching Assistant',
        'assigned' => 'Assistant Assigned',
        'arriving' => 'Assistant Arriving',
        'started' => 'Service Started',
        'completed' => 'Service Completed',
        'cancelled' => 'Cancelled',
        _ => status,
      };
}
