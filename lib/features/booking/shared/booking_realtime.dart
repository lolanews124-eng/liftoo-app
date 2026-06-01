import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/models/booking_model.dart';

/// Listen for realtime booking updates on a specific booking.
void listenBookingUpdates(
  WidgetRef ref,
  String bookingId,
  void Function(BookingModel booking) onUpdate,
) {
  final socket = ref.read(socketServiceProvider);
  socket.joinBooking(bookingId);
  socket.on('booking:updated', (data) {
    if (data is! Map) return;
    final payload = data['booking'];
    if (payload is! Map<String, dynamic>) return;
    if (payload['id'] != bookingId) return;
    onUpdate(BookingModel.fromJson(payload));
  });
}

void stopBookingUpdates(WidgetRef ref) {
  ref.read(socketServiceProvider).off('booking:updated');
}
