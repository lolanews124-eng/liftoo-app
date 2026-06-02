class NearbyAssistantModel {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final double rating;
  final int totalJobs;
  final String? assistantCode;
  final String? avatarUrl;

  const NearbyAssistantModel({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    this.distanceKm,
    this.rating = 5,
    this.totalJobs = 0,
    this.assistantCode,
    this.avatarUrl,
  });

  factory NearbyAssistantModel.fromJson(Map<String, dynamic> json) => NearbyAssistantModel(
        id: json['id'] as String,
        name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] as String : 'Assistant',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        distanceKm: double.tryParse('${json['distanceKm']}'),
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
        assistantCode: json['assistantCode'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  bool get hasCoordinates => lat != null && lng != null;
}
