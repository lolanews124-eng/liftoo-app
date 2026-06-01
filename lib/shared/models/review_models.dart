import 'booking_model.dart';

class AssistantStatsModel {
  final String userId;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int totalJobs;
  final int reviewCount;

  const AssistantStatsModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.totalJobs,
    required this.reviewCount,
  });

  factory AssistantStatsModel.fromJson(Map<String, dynamic> json) => AssistantStatsModel(
        userId: json['userId'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Assistant',
        avatarUrl: json['avatarUrl'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      );

  factory AssistantStatsModel.fromAssistantMap(Map<String, dynamic> assistant) {
    final profile = assistant['assistantProfile'] as Map<String, dynamic>?;
    return AssistantStatsModel(
      userId: assistant['id'] as String? ?? '',
      name: assistant['name'] as String? ?? 'Assistant',
      avatarUrl: assistant['avatarUrl'] as String?,
      rating: (profile?['rating'] as num?)?.toDouble() ?? 5,
      totalJobs: (profile?['totalJobs'] as num?)?.toInt() ?? 0,
      reviewCount: (profile?['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ServiceReviewResult {
  final String id;
  final int stars;
  final String? comment;
  final String nextStep;
  final AssistantStatsModel? assistantStats;

  const ServiceReviewResult({
    required this.id,
    required this.stars,
    this.comment,
    required this.nextStep,
    this.assistantStats,
  });

  factory ServiceReviewResult.fromJson(Map<String, dynamic> json) => ServiceReviewResult(
        id: json['id'] as String,
        stars: json['stars'] as int,
        comment: json['comment'] as String?,
        nextStep: json['nextStep'] as String? ?? 'rate_app',
        assistantStats: json['assistantStats'] != null
            ? AssistantStatsModel.fromJson(json['assistantStats'] as Map<String, dynamic>)
            : null,
      );
}

class PaymentResultModel {
  final Map<String, dynamic>? payment;
  final BookingModel? booking;
  final String nextStep;
  final double? walletBalance;

  const PaymentResultModel({
    this.payment,
    this.booking,
    required this.nextStep,
    this.walletBalance,
  });

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('bookingId') && !json.containsKey('nextStep') && !json.containsKey('booking')) {
      return PaymentResultModel(
        payment: json,
        nextStep: 'rate_service',
      );
    }
    return PaymentResultModel(
      payment: json['payment'] as Map<String, dynamic>?,
      booking: json['booking'] != null ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>) : null,
      nextStep: json['nextStep'] as String? ?? 'rate_service',
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
    );
  }
}
