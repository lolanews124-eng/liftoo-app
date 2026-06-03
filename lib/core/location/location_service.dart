import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/geocode/data/geocode_repository.dart';
import '../../shared/models/service_location_model.dart';

/// GPS via Geolocator; addresses via backend geocode API (fallback: device geocoding).
class LocationService {
  static GeocodeRepository? _geocode;

  static void useGeocode(GeocodeRepository repository) => _geocode = repository;

  static const defaultLat = 19.076;
  static const defaultLng = 72.8777;
  static const currentLocationId = ServiceLocationModel.currentLocationId;

  static Future<({double lat, double lng})> currentOrDefault() async {
    final loc = await resolveCurrentLocation();
    return (lat: loc.lat, lng: loc.lng);
  }

  /// Real device coordinates when possible (no Mumbai fallback). For assistant online/location sync.
  static Future<({double lat, double lng})?> tryCurrentCoords() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _lastKnownCoords();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnownCoords();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return _lastKnownCoords();
    }
  }

  static Future<({double lat, double lng})?> _lastKnownCoords() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {}
    return null;
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
      return fromCoordinates(pos.latitude, pos.longitude, isCurrent: true);
    } catch (_) {
      return _fallbackLocation();
    }
  }

  static Future<ServiceLocationModel> fromCoordinates(
    double lat,
    double lng, {
    bool isCurrent = false,
  }) =>
      _resolveAddress(lat, lng, isCurrent: isCurrent);

  static ServiceLocationModel _fallbackLocation() => ServiceLocationModel(
        id: currentLocationId,
        name: 'Current location',
        address: 'Enable GPS for accurate pickup',
        city: '',
        lat: defaultLat,
        lng: defaultLng,
        isCurrentLocation: true,
      );

  static Future<ServiceLocationModel> _resolveAddress(
    double lat,
    double lng, {
    bool isCurrent = false,
  }) async {
    final geocode = _geocode;
    if (geocode != null) {
      try {
        final place = await geocode.reverse(lat: lat, lng: lng);
        return place.toServiceLocation(
          id: isCurrent ? currentLocationId : null,
          isCurrent: isCurrent,
        );
      } catch (_) {}
    }
    return _deviceReverseGeocode(lat, lng, isCurrent: isCurrent);
  }

  static Future<ServiceLocationModel> _deviceReverseGeocode(
    double lat,
    double lng, {
    bool isCurrent = false,
  }) async {
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
          isCurrentLocation: isCurrent,
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
        id: isCurrent ? currentLocationId : 'geo-$lat-$lng',
        name: label,
        address: formatted.isNotEmpty ? formatted : label,
        city: locality,
        lat: lat,
        lng: lng,
        isCurrentLocation: isCurrent,
      );
    } catch (_) {
      return ServiceLocationModel(
        id: currentLocationId,
        name: 'Current location',
        address: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        city: '',
        lat: lat,
        lng: lng,
        isCurrentLocation: isCurrent,
      );
    }
  }
}
