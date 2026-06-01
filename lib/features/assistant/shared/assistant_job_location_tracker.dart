import 'dart:async';
import '../../../core/location/location_service.dart';
import '../../../core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ping assistant GPS while on an active job so customers see live tracking.
class AssistantJobLocationTracker {
  Timer? _timer;
  String? _bookingId;

  void start(WidgetRef ref, String bookingId) {
    if (_bookingId == bookingId && _timer != null) return;
    stop();
    _bookingId = bookingId;
    _ping(ref);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _ping(ref));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _bookingId = null;
  }

  Future<void> _ping(WidgetRef ref) async {
    try {
      final coords = await LocationService.currentOrDefault();
      await ref.read(bookingRepositoryProvider).updateAssistantLocation(
            lat: coords.lat,
            lng: coords.lng,
          );
    } catch (_) {}
  }
}

final assistantJobLocationTrackerProvider = Provider<AssistantJobLocationTracker>((ref) {
  final tracker = AssistantJobLocationTracker();
  ref.onDispose(tracker.stop);
  return tracker;
});
