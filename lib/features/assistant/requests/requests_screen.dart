import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liftoo_card.dart';
import 'assistant_booking_request_flow.dart';
import 'booking_request_popup.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  List<BookingModel> _requests = [];

  void _onSocketRequest(dynamic _) => _load();

  @override
  void initState() {
    super.initState();
    _load();
    ref.read(socketServiceProvider).on('booking:request', _onSocketRequest);
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('booking:request', _onSocketRequest);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(bookingRepositoryProvider).getNearbyRequests();
      if (mounted) setState(() => _requests = list);
    } catch (_) {}
  }

  Future<void> _accept(BookingModel b) async {
    HapticFeedback.mediumImpact();
    try {
      final accepted = await ref.read(bookingRepositoryProvider).acceptBooking(b.id);
      if (mounted) context.push('/assistant/active/${accepted.id}');
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
      await _load();
    }
  }

  Future<void> _reject(BookingModel b) async {
    final reason = await showRejectReasonDialog(context, venueName: b.venueName);
    if (reason == null || !mounted) return;
    HapticFeedback.lightImpact();
    await ref.read(bookingRepositoryProvider).rejectBooking(b.id, reason: reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking requests')),
      body: _requests.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No requests',
              subtitle: 'Go online to receive nearby bookings',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _requests.length,
                itemBuilder: (context, i) {
                  final b = _requests[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LiftooCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.category?.name ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(b.venueName, style: const TextStyle(color: AppColors.textSecondary)),
                          Text(b.addressFormatted, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (b.distanceKm != null) ...[
                            const SizedBox(height: 4),
                            Text('${b.distanceKm} km away', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
                              Text(' ${b.durationMin} min'),
                              const Spacer(),
                              Text('₹${(b.serviceFee * 0.8).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(b),
                                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                                  onPressed: () => presentAssistantBookingRequest(ref, booking: b),
                                  child: const Text('Received', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _accept(b),
                                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
