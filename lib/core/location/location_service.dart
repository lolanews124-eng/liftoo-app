import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/models/service_location_model.dart';

/// GPS + reverse geocoding — no manual admin areas.
class LocationService {
  static const defaultLat = 19.076;
  static const defaultLng = 72.8777;
  static const currentLocationId = ServiceLocationModel.currentLocationId;

  static Future<({double lat, double lng})> currentOrDefault() async {
    final loc = await resolveCurrentLocation();
    return (lat: loc.lat, lng: loc.lng);
  }

  static Future<ServiceLocationModel> resolveCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _fallbackLocation();

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallbackLocation();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return _fromCoordinates(pos.latitude, pos.longitude);
    } catch (_) {
      return _fallbackLocation();
    }
  }

  static Future<ServiceLocationModel> fromCoordinates(double lat, double lng) =>
      _fromCoordinates(lat, lng);

  static ServiceLocationModel _fallbackLocation() => ServiceLocationModel(
        id: currentLocationId,
        name: 'Current location',
        address: 'Enable GPS for accurate pickup',
        city: '',
        lat: defaultLat,
        lng: defaultLng,
        isCurrentLocation: true,
      );

  static Future<ServiceLocationModel> _fromCoordinates(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) {
        return ServiceLocationModel(
          id: currentLocationId,
          name: 'Current location',
          address: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          city: '',
          lat: lat,
          lng: lng,
          isCurrentLocation: true,
        );
      }
      final p = places.first;
      final locality = p.subLocality?.trim().isNotEmpty == true
          ? p.subLocality!
          : p.locality?.trim().isNotEmpty == true
              ? p.locality!
              : p.administrativeArea ?? '';
      final street = [p.name, p.street, p.thoroughfare]
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .join(', ');
      final label = street.isNotEmpty ? street : (locality.isNotEmpty ? locality : 'Current location');
      final formatted = [
        if (street.isNotEmpty) street,
        if (p.subLocality?.isNotEmpty == true) p.subLocality,
        if (p.locality?.isNotEmpty == true) p.locality,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea,
        if (p.postalCode?.isNotEmpty == true) p.postalCode,
      ].whereType<String>().join(', ');

      return ServiceLocationModel(
        id: currentLocationId,
        name: label,
        address: formatted.isNotEmpty ? formatted : label,
        city: locality,
        lat: lat,
        lng: lng,
        isCurrentLocation: true,
      );
    } catch (_) {
      return ServiceLocationModel(
        id: currentLocationId,
        name: 'Current location',
        address: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        city: '',
        lat: lat,
        lng: lng,
        isCurrentLocation: true,
      );
    }
  }
}
