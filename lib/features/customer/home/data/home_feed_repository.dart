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

  factory HomeFeedAd.fromJson(Map<String, dynamic> json) => HomeFeedAd(
        id: json['id'] as String,
        title: json['title'] as String?,
        imageUrl: json['imageUrl'] as String,
        buttonLabel: json['buttonLabel'] as String?,
        buttonLink: json['buttonLink'] as String?,
        buttonAction: json['buttonAction'] as String? ?? 'url',
      );
}

class HomeFeedRepository {
  final ApiClient _api;

  HomeFeedRepository(this._api);

  Future<HomeFeedAd?> getActiveAd() async {
    final res = await _api.get<Map<String, dynamic>>('/api/v1/home-feed/ad');
    final ad = res['ad'];
    if (ad is! Map<String, dynamic>) return null;
    return HomeFeedAd.fromJson(ad);
  }
}
