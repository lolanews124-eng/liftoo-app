class BookingZoneAvailability {
  final String label;
  final int count;

  const BookingZoneAvailability({required this.label, required this.count});

  factory BookingZoneAvailability.fromJson(Map<String, dynamic> json) =>
      BookingZoneAvailability(
        label: json['label'] as String,
        count: json['count'] as int,
      );
}

class BookingSearchAvailability {
  final int nearbyAvailable;
  final double matchRadiusKm;
  final String areaLabel;
  final List<BookingZoneAvailability> zones;
  final int notifiedCount;
  final String message;

  const BookingSearchAvailability({
    required this.nearbyAvailable,
    required this.matchRadiusKm,
    required this.areaLabel,
    required this.zones,
    required this.notifiedCount,
    required this.message,
  });

  factory BookingSearchAvailability.fromJson(Map<String, dynamic> json) {
    final zones = (json['zones'] as List<dynamic>? ?? [])
        .map((e) => BookingZoneAvailability.fromJson(e as Map<String, dynamic>))
        .toList();
    return BookingSearchAvailability(
      nearbyAvailable: json['nearbyAvailable'] as int? ?? 0,
      matchRadiusKm: (json['matchRadiusKm'] as num?)?.toDouble() ?? 10,
      areaLabel: json['areaLabel'] as String? ?? 'Your area',
      zones: zones,
      notifiedCount: json['notifiedCount'] as int? ?? 0,
      message: json['message'] as String? ?? 'Searching for assistants…',
    );
  }
}

class BookingTrackingPoint {
  final double lat;
  final double lng;
  final String? label;
  final String? name;
  final String? address;

  const BookingTrackingPoint({
    required this.lat,
    required this.lng,
    this.label,
    this.name,
    this.address,
  });

  factory BookingTrackingPoint.fromJson(Map<String, dynamic> json) =>
      BookingTrackingPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        label: json['label'] as String?,
        name: json['name'] as String?,
        address: json['address'] as String?,
      );
}

class BookingTrackingModel {
  final BookingTrackingPoint customer;
  final BookingTrackingPoint? assistant;
  final String? distanceKm;
  final int? etaMinutes;
  final String statusMessage;
  final double progress;

  const BookingTrackingModel({
    required this.customer,
    this.assistant,
    this.distanceKm,
    this.etaMinutes,
    required this.statusMessage,
    this.progress = 0,
  });

  factory BookingTrackingModel.fromJson(Map<String, dynamic> json) {
    final assistantJson = json['assistant'] as Map<String, dynamic>?;
    return BookingTrackingModel(
      customer: BookingTrackingPoint.fromJson(json['customer'] as Map<String, dynamic>),
      assistant: assistantJson != null ? BookingTrackingPoint.fromJson(assistantJson) : null,
      distanceKm: json['distanceKm']?.toString(),
      etaMinutes: json['etaMinutes'] as int?,
      statusMessage: json['statusMessage'] as String? ?? 'Tracking assistant',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}
