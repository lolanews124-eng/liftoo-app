import '../../../../core/config/media_url.dart';
import '../../../../core/network/api_client.dart';

class HomeFeedAd {
  final String id;
  final String? title;
  final String imageUrl;
  final String? buttonLabel;
  final String? buttonLink;
  final String buttonAction;

  const HomeFeedAd({
    required this.id,
    this.title,
    required this.imageUrl,
    this.buttonLabel,
    this.buttonLink,
    this.buttonAction = 'url',
  });

  factory HomeFeedAd.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['imageUrl'] ?? json['image_url']) as String?;
    if (rawImage == null || rawImage.isEmpty) {
      throw const FormatException('Home feed ad missing imageUrl');
    }
    return HomeFeedAd(
      id: json['id'] as String,
      title: json['title'] as String?,
      imageUrl: resolveMediaUrl(rawImage),
      buttonLabel: (json['buttonLabel'] ?? json['button_label']) as String?,
      buttonLink: (json['buttonLink'] ?? json['button_link']) as String?,
      buttonAction: (json['buttonAction'] ?? json['button_action']) as String? ?? 'url',
    );
  }
}

class HomeFeedRepository {
  final ApiClient _api;

  HomeFeedRepository(this._api);

  Future<List<HomeFeedAd>> getActiveAds() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/v1/home-feed/ad');
      final rawAds = res['ads'];
      if (rawAds is List) {
        return rawAds
            .whereType<Map<String, dynamic>>()
            .map(HomeFeedAd.fromJson)
            .toList();
      }
      final ad = res['ad'];
      if (ad is Map<String, dynamic>) return [HomeFeedAd.fromJson(ad)];
      return [];
    } catch (_) {
      return [];
    }
  }
}
