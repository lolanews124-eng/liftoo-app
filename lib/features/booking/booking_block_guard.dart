import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/booking_model.dart';

/// Latest booking that prevents the customer from starting another (incl. unpaid completed).
final customerBlockingBookingProvider = FutureProvider<BookingModel?>((ref) async {
  return ref.read(bookingRepositoryProvider).getCustomerBlockingBooking();
});

void navigateToResolveBlockingBooking(BuildContext context, BookingModel booking) {
  if (booking.isPaymentPending) {
    context.push('/payment/${booking.id}');
    return;
  }
  if (booking.isActive) {
    context.push('/customer/booking/${booking.id}');
    return;
  }
  context.go('/customer/bookings');
}

Future<bool> canCustomerStartNewBooking(WidgetRef ref) async {
  final blocking = await ref.read(bookingRepositoryProvider).getCustomerBlockingBooking();
  return blocking == null;
}
