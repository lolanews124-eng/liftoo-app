import 'dart:async' show Timer, unawaited;

import '../../../core/location/location_service.dart';
import '../../../core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Keeps assistant GPS fresh on the backend while online (matching + nearby map).
class AssistantAvailabilityTracker {
  Timer? _timer;

  bool get isRunning => _timer != null;

  void start(WidgetRef ref) {
    if (_timer != null) return;
    unawaited(refreshNow(ref));
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => refreshNow(ref));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshNow(WidgetRef ref) async {
    final user = ref.read(authProvider).user;
    if (user?.activeRole != 'assistant' || !(user?.isOnline ?? false)) return;
    try {
      final coords = await LocationService.tryCurrentCoords();
      if (coords == null) return;
      await ref.read(bookingRepositoryProvider).updateAssistantLocation(
            lat: coords.lat,
            lng: coords.lng,
          );
    } catch (_) {}
  }
}

final assistantAvailabilityTrackerProvider = Provider<AssistantAvailabilityTracker>((ref) {
  final tracker = AssistantAvailabilityTracker();
  ref.onDispose(tracker.stop);
  return tracker;
});
