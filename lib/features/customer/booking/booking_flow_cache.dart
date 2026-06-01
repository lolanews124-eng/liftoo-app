/// Tracks bookings paid in this session before backend sync catches up.
class BookingFlowCache {
  BookingFlowCache._();
  static final instance = BookingFlowCache._();

  final Set<String> _justPaid = {};

  void markPaid(String bookingId) => _justPaid.add(bookingId);

  bool wasJustPaid(String bookingId) => _justPaid.contains(bookingId);

  void clearPaid(String bookingId) => _justPaid.remove(bookingId);
}
