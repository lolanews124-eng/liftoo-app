import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../booking/shared/booking_realtime.dart';
import '../shared/assistant_job_location_tracker.dart';

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

  Future<void> _startNavigation() async {
    setState(() => _loading = true);
    try {
      await ref.read(bookingRepositoryProvider).setArriving(widget.bookingId);
      await _load();
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
      await ref.read(bookingRepositoryProvider).completeBooking(widget.bookingId);
      if (mounted) context.go('/assistant');
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
          : KeyboardAwareScroll(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.customer?['name'] ?? 'Customer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(b.addressFormatted, style: const TextStyle(color: AppColors.textSecondary)),
                        Text('Status: ${b.status}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                    GradientButton(
                      label: 'Start navigation',
                      isLoading: _loading,
                      onPressed: _startNavigation,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (b.status == 'assigned' || b.status == 'arriving') ...[
                    const Text('Enter customer OTP to start', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    const SizedBox(height: 24),
                    GradientButton(label: 'Complete service', isLoading: _loading, onPressed: _complete),
                  ],
                ],
              ),
            ),
    );
  }
}
