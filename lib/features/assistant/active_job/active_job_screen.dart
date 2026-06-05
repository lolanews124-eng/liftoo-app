import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/assistant_collect_payment_dialog.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../booking/shared/booking_realtime.dart';
import '../shared/assistant_job_location_tracker.dart';
import '../shared/assistant_home_refresh_provider.dart';
import 'widgets/assistant_job_steps.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  BookingModel? _booking;
  final _otpController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenBookingUpdates(ref, widget.bookingId, (booking) {
        if (mounted) setState(() => _booking = booking);
      });
    });
  }

  @override
  void dispose() {
    ref.read(assistantJobLocationTrackerProvider).stop();
    stopBookingUpdates(ref);
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
    if (!mounted) return;
    setState(() => _booking = b);
    if (['assigned', 'arriving', 'started'].contains(b.status)) {
      ref.read(assistantJobLocationTrackerProvider).start(ref, widget.bookingId);
    } else {
      ref.read(assistantJobLocationTrackerProvider).stop();
    }
  }

  Future<void> _openCustomerOnMaps(BookingModel b) async {
    final uri = Uri.parse(
      'google.navigation:q=${b.lat},${b.lng}&mode=d',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${b.lat},${b.lng}&travelmode=driving',
    );
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _startNavigation() async {
    final b = _booking;
    if (b == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(bookingRepositoryProvider).setArriving(widget.bookingId);
      await _load();
      if (mounted) await _openCustomerOnMaps(b);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start navigation')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await ref.read(bookingRepositoryProvider).verifyOtp(widget.bookingId, _otpController.text.trim());
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(bookingRepositoryProvider).completeBooking(widget.bookingId);
      if (!mounted) return;
      await showAssistantCollectPaymentDialog(
        context,
        ref: ref,
        booking: result.booking,
        assistantEarning: result.assistantEarning,
        paymentConfirmOtp: result.booking.paymentConfirmOtp,
      );
      if (mounted) {
        refreshAssistantHome(ref);
        context.go('/assistant');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Active job'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chat/${widget.bookingId}'),
          ),
        ],
      ),
      body: b == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: KeyboardAwareScroll(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssistantJobSteps(status: b.status),
                  const SizedBox(height: 16),
                  LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.customer?['name'] ?? 'Customer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(b.addressFormatted, style: const TextStyle(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(_statusLabel(b.status), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:+91${b.customer?['phone'] ?? ''}')),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('https://maps.google.com/?q=${b.lat},${b.lng}')),
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (b.status == 'assigned') ...[
                    const Text('Step 3: Go to pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    const Text(
                      'Start navigation when you leave for the customer location.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Start navigation',
                      isLoading: _loading,
                      onPressed: _startNavigation,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (b.status == 'arriving') ...[
                    const Text('Step 4: At pickup — verify OTP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask the customer for their 4-digit OTP to start the service.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (b.status == 'assigned' || b.status == 'arriving') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      scrollPadding: keyboardScrollPadding(context),
                      decoration: const InputDecoration(hintText: '4-digit OTP'),
                    ),
                    GradientButton(label: 'Verify & Start', isLoading: _loading, onPressed: _verifyOtp),
                  ],
                  if (b.status == 'started') ...[
                    const Text('Step 5: Complete service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 12),
                    GradientButton(label: 'Complete service', isLoading: _loading, onPressed: _complete),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'assigned' => 'Accepted — ready to navigate',
        'arriving' => 'On the way to customer',
        'started' => 'Service in progress',
        'completed' => 'Completed',
        _ => status,
      };
}
