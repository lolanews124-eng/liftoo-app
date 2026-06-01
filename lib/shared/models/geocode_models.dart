import 'service_location_model.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) => PlaceSuggestion(
        placeId: json['placeId'] as String,
        description: json['description'] as String? ?? '',
        mainText: json['mainText'] as String? ?? '',
        secondaryText: json['secondaryText'] as String? ?? '',
      );
}

class GeocodePlace {
  final String formattedAddress;
  final String label;
  final String? locality;
  final double lat;
  final double lng;
  final String? placeId;

  const GeocodePlace({
    required this.formattedAddress,
    required this.label,
    this.locality,
    required this.lat,
    required this.lng,
    this.placeId,
  });

  factory GeocodePlace.fromJson(Map<String, dynamic> json) => GeocodePlace(
        formattedAddress: json['formattedAddress'] as String? ?? '',
        label: json['label'] as String? ?? '',
        locality: json['locality'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        placeId: json['placeId'] as String?,
      );

  ServiceLocationModel toServiceLocation({String? id, bool isCurrent = false}) {
    final city = locality?.trim() ?? '';
    final resolvedId = id ??
        placeId ??
        (isCurrent ? ServiceLocationModel.currentLocationId : 'place-$lat-$lng');
    return ServiceLocationModel(
      id: resolvedId,
      name: label.isNotEmpty ? label : formattedAddress.split(',').first.trim(),
      address: formattedAddress.isNotEmpty ? formattedAddress : label,
      city: city,
      lat: lat,
      lng: lng,
      isCurrentLocation: isCurrent,
    );
  }
}
