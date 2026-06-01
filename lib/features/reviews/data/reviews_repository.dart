import 'package:flutter/foundation.dart';
import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/review_models.dart';

class ReviewsRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  ReviewsRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<AssistantStatsModel> getAssistantStats(String userId) => _resolve(
        () async {
          final data = await _api.get<Map<String, dynamic>>('/api/v1/assistants/$userId/stats');
          return AssistantStatsModel.fromJson(data);
        },
        () => DevDataStore.instance.getAssistantStats(userId),
      );

  Future<ServiceReviewResult> submitServiceReview(
    String bookingId,
    int stars, {
    String? comment,
  }) =>
      _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/ratings', data: {
            'bookingId': bookingId,
            'stars': stars,
            if (comment != null) 'comment': comment,
          });
          return ServiceReviewResult.fromJson(data);
        },
        () => DevDataStore.instance.submitServiceReview(bookingId, stars, comment: comment),
      );

  Future<void> submitAppReview(
    int stars, {
    String? bookingId,
    String? comment,
  }) =>
      _resolve(
        () => _api.post('/api/v1/app-reviews', data: {
          'stars': stars,
          if (bookingId != null) 'bookingId': bookingId,
          if (comment != null) 'comment': comment,
          'platform': _platform,
        }),
        () => DevDataStore.instance.submitAppReview(stars, bookingId: bookingId, comment: comment),
      );

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
