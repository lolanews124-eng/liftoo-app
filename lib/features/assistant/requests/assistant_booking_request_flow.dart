import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/root_navigator.dart';
import '../../../shared/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'booking_request_popup.dart';

bool assistantCanReceiveRequests(WidgetRef ref) {
  final user = ref.read(authProvider).user;
  return user?.activeRole == 'assistant' && (user?.isOnline ?? false);
}

Future<void> presentAssistantBookingRequest(
  WidgetRef ref, {
  required BookingModel booking,
}) async {
  final ctx = rootNavigatorContext;
  if (ctx == null || !ctx.mounted) return;

  await showBookingRequestPopup(
    ctx,
    booking: booking,
    onAccept: () async {
      try {
        final accepted = await ref.read(bookingRepositoryProvider).acceptBooking(booking.id);
        if (ctx.mounted) ctx.push('/assistant/active/${accepted.id}');
      } catch (e) {
        if (ctx.mounted) showAppErrorSnackBar(ctx, e);
      }
    },
    onReject: (reason) async {
      await ref.read(bookingRepositoryProvider).rejectBooking(booking.id, reason: reason);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    },
  );
}
