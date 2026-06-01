class ServiceLocationModel {
  static const currentLocationId = 'gps-current';

  final String id;
  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;
  final bool isCurrentLocation;

  const ServiceLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
    this.isCurrentLocation = false,
  });

  String get displayName => city.isNotEmpty ? '$name, $city' : name;

  factory ServiceLocationModel.fromJson(Map<String, dynamic> json) => ServiceLocationModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        isCurrentLocation: json['isCurrentLocation'] as bool? ?? false,
      );
}
