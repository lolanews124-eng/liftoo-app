import '../../../core/location/location_service.dart';
import '../../../core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Toggle assistant online state with GPS coordinates when going online.
Future<void> setAssistantOnline(WidgetRef ref, bool targetOnline) async {
  double? lat;
  double? lng;
  if (targetOnline) {
    final coords = await LocationService.currentOrDefault();
    lat = coords.lat;
    lng = coords.lng;
  }
  await ref.read(bookingRepositoryProvider).setOnline(targetOnline, lat: lat, lng: lng);
  await ref.read(authProvider.notifier).refreshUser();
}
