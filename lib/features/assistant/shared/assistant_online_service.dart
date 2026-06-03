import '../../../core/location/location_service.dart';
import '../../../core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'assistant_availability_tracker.dart';

/// Toggle assistant online state, sync GPS with backend, and start location heartbeat.
Future<void> setAssistantOnline(WidgetRef ref, bool targetOnline) async {
  double? lat;
  double? lng;
  if (targetOnline) {
    final coords = await LocationService.tryCurrentCoords();
    if (coords == null) {
      throw Exception(
        'Turn on location (GPS) so customers can find you nearby.',
      );
    }
    lat = coords.lat;
    lng = coords.lng;
  }

  await ref.read(bookingRepositoryProvider).setOnline(targetOnline, lat: lat, lng: lng);
  await ref.read(authProvider.notifier).refreshUser();

  final tracker = ref.read(assistantAvailabilityTrackerProvider);
  if (targetOnline) {
    tracker.start(ref);
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    if (token != null) {
      ref.read(socketServiceProvider).connect(token);
    }
  } else {
    tracker.stop();
  }
}
