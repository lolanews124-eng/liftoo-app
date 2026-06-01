import '../../../core/network/api_client.dart';
import '../../../shared/models/geocode_models.dart';

class GeocodeRepository {
  final ApiClient _api;

  GeocodeRepository(this._api);

  Future<bool> isEnabled() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/geocode/config');
      return data['googleMapsEnabled'] == true ||
          data['googleSearchEnabled'] == true ||
          data['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<GeocodePlace> reverse({required double lat, required double lng}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/v1/geocode/reverse',
      query: {'lat': lat, 'lng': lng},
    );
    return GeocodePlace.fromJson(data);
  }

  Future<List<PlaceSuggestion>> autocomplete({
    required String query,
    double? lat,
    double? lng,
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/api/v1/geocode/autocomplete',
      query: {
        'q': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return data.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GeocodePlace> getPlace(String placeId) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/v1/geocode/place',
      query: {'placeId': placeId},
    );
    return GeocodePlace.fromJson(data);
  }

  Future<GeocodePlace> forward(String address) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/v1/geocode/forward',
      query: {'address': address},
    );
    return GeocodePlace.fromJson(data);
  }
}
