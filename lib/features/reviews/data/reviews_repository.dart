import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/review_models.dart';

class ReviewsRepository {
  final ApiClient _api;

  ReviewsRepository(this._api, _);

  Future<AssistantStatsModel> getAssistantStats(String userId) async {
    final data = await _api.get<Map<String, dynamic>>('/api/v1/assistants/$userId/stats');
    return AssistantStatsModel.fromJson(data);
  }

  Future<ServiceReviewResult> submitServiceReview(
    String bookingId,
    int stars, {
    String? comment,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/ratings', data: {
      'bookingId': bookingId,
      'stars': stars,
      if (comment != null) 'comment': comment,
    });
    return ServiceReviewResult.fromJson(data);
  }

  Future<void> submitAppReview(
    int stars, {
    String? bookingId,
    String? comment,
  }) =>
      _api.post('/api/v1/app-reviews', data: {
        'stars': stars,
        if (bookingId != null) 'bookingId': bookingId,
        if (comment != null) 'comment': comment,
        'platform': _platform,
      });

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }
}
