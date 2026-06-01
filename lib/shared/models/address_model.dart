import 'service_location_model.dart';

class AddressModel {
  final String id;
  final String label;
  final String formattedAddress;
  final double lat;
  final double lng;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as String,
        label: json['label'] as String,
        formattedAddress: json['formattedAddress'] as String? ?? json['formatted_address'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      );

  ServiceLocationModel toServiceLocation() => ServiceLocationModel(
        id: id,
        name: label,
        address: formattedAddress,
        city: _extractCity(formattedAddress),
        lat: lat,
        lng: lng,
      );

  static String _extractCity(String address) {
    final parts = address.split(',').map((p) => p.trim()).toList();
    return parts.length > 1 ? parts.last : '';
  }
}
