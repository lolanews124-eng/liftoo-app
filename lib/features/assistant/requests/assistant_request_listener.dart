import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'booking_request_popup.dart';

/// Listens for incoming booking requests and shows popup for assistants.
class AssistantRequestListener extends ConsumerStatefulWidget {
  final Widget child;

  const AssistantRequestListener({super.key, required this.child});

  @override
  ConsumerState<AssistantRequestListener> createState() => _AssistantRequestListenerState();
}

class _AssistantRequestListenerState extends ConsumerState<AssistantRequestListener> {
  bool _dialogOpen = false;
  final _shownBookingIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    ref.read(socketServiceProvider).on('booking:request', _onRequest);
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('booking:request', _onRequest);
    super.dispose();
  }

  Future<void> _onRequest(dynamic data) async {
    final user = ref.read(authProvider).user;
    if (user?.activeRole != 'assistant' || !(user?.isOnline ?? false)) return;
    if (user?.assistantProfile?.adminVerified != true) return;
    if (_dialogOpen || !mounted) return;

    Map<String, dynamic>? json;
    if (data is Map) {
      final booking = data['booking'] ?? data;
      if (booking is Map<String, dynamic>) {
        json = booking;
      } else if (booking is Map) {
        json = Map<String, dynamic>.from(booking);
      }
    }
    if (json == null) return;

    final booking = BookingModel.fromJson(json);
    if (_shownBookingIds.contains(booking.id)) return;
    _shownBookingIds.add(booking.id);

    _dialogOpen = true;
    await showBookingRequestPopup(
      context,
      booking: booking,
      onAccept: () async {
        try {
          final accepted = await ref.read(bookingRepositoryProvider).acceptBooking(booking.id);
          if (mounted) context.push('/assistant/active/${accepted.id}');
        } catch (e) {
          if (mounted) showAppErrorSnackBar(context, e);
        }
      },
      onReject: (reason) async {
        await ref.read(bookingRepositoryProvider).rejectBooking(booking.id, reason: reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request declined')),
          );
        }
      },
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
