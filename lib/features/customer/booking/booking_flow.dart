import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/booking_model.dart';

void navigateBookingNextStep(BuildContext context, BookingModel booking, {String? overrideStep}) {
  final step = overrideStep ?? booking.nextStep;
  switch (step) {
    case 'pay':
      context.push('/customer/payment/${booking.id}');
    case 'rate_service':
      openServiceReview(context, booking.id);
    case 'rate_app':
      openAppReview(context, booking.id);
    case 'track':
      context.push('/customer/booking/${booking.id}');
    default:
      context.go('/customer');
  }
}

void openServiceReview(BuildContext context, String bookingId) {
  context.go('/review/service/$bookingId');
}

void openAppReview(BuildContext context, String bookingId) {
  context.go('/review/app/$bookingId');
}
