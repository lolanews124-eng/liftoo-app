import 'booking_tracking_model.dart';

class ServiceCategoryModel {
  final String id;
  final String slug;
  final String name;
  final String? icon;
  final double baseRate;

  const ServiceCategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    this.icon,
    required this.baseRate,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) =>
      ServiceCategoryModel(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        baseRate: (json['baseRate'] as num).toDouble(),
      );
}

class BookingModel {
  final String id;
  final String status;
  final int durationMin;
  final String venueName;
  final DateTime scheduledAt;
  final String addressFormatted;
  final double lat;
  final double lng;
  final double serviceFee;
  final double platformFee;
  final double totalAmount;
  final String? serviceOtp;
  final ServiceCategoryModel? category;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? assistant;
  final List<StatusHistoryModel> statusHistory;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? rating;
  final Map<String, dynamic>? appReview;
  final String? distanceKm;
  final BookingSearchAvailability? searchAvailability;
  final BookingTrackingModel? tracking;
  final String? paymentConfirmOtp;
  final double? assistantEarningAmount;
  final double? companyShareAmount;

  const BookingModel({
    required this.id,
    required this.status,
    required this.durationMin,
    required this.venueName,
    required this.scheduledAt,
    required this.addressFormatted,
    required this.lat,
    required this.lng,
    required this.serviceFee,
    required this.platformFee,
    required this.totalAmount,
    this.serviceOtp,
    this.category,
    this.customer,
    this.assistant,
    this.statusHistory = const [],
    this.payment,
    this.rating,
    this.appReview,
    this.distanceKm,
    this.searchAvailability,
    this.tracking,
    this.paymentConfirmOtp,
    this.assistantEarningAmount,
    this.companyShareAmount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final history = json['statusHistory'] as List<dynamic>? ?? [];
    return BookingModel(
      id: json['id'] as String,
      status: json['status'] as String,
      durationMin: (json['durationMin'] as num).toInt(),
      venueName: json['venueName'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      addressFormatted: json['addressFormatted'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      serviceOtp: json['serviceOtp'] as String?,
      category: cat != null ? ServiceCategoryModel.fromJson(cat) : null,
      customer: json['customer'] as Map<String, dynamic>?,
      assistant: json['assistant'] as Map<String, dynamic>?,
      statusHistory: history
          .map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      payment: json['payment'] as Map<String, dynamic>?,
      rating: json['rating'] as Map<String, dynamic>?,
      appReview: json['appReview'] as Map<String, dynamic>?,
      distanceKm: json['distanceKm']?.toString(),
      searchAvailability: json['searchAvailability'] != null
          ? BookingSearchAvailability.fromJson(json['searchAvailability'] as Map<String, dynamic>)
          : null,
      tracking: json['tracking'] != null
          ? BookingTrackingModel.fromJson(json['tracking'] as Map<String, dynamic>)
          : null,
      paymentConfirmOtp: json['paymentConfirmOtp'] as String?,
      assistantEarningAmount: (json['assistantEarningAmount'] as num?)?.toDouble(),
      companyShareAmount: (json['companyShareAmount'] as num?)?.toDouble(),
    );
  }

  bool get isPaymentPending {
    if (status != 'completed') return false;
    if (payment == null) return true;
    return payment!['status'] != 'completed';
  }

  bool get isCashAwaitingCustomerConfirm {
    if (payment?['method'] != 'cash') return false;
    return payment!['cashCollectedAt'] != null && !isPaid;
  }

  bool get isPaid {
    if (payment == null) return false;
    final status = payment!['status'] as String?;
    if (status == 'completed') return true;
    // Legacy rows that only stored paidAt without status.
    if (status != 'pending' && payment!['paidAt'] != null) return true;
    return false;
  }
  bool get hasServiceReview => rating != null;
  bool get hasAppReview => appReview != null;

  String get nextStep {
    if (status != 'completed') return 'track';
    if (!isPaid) return 'pay';
    if (!hasServiceReview) return 'rate_service';
    if (!hasAppReview) return 'rate_app';
    return 'done';
  }

  bool get isActive => !['completed', 'cancelled'].contains(status);

  /// Blocks starting another booking until service is done and payment is completed.
  bool get blocksNewBooking => isActive || isPaymentPending;

  DateTime? get serviceStartedAt {
    for (final h in statusHistory.reversed) {
      if (h.status == 'started') return h.createdAt;
    }
    return null;
  }

  DateTime? get serviceCompletedAt {
    for (final h in statusHistory.reversed) {
      if (h.status == 'completed') return h.createdAt;
    }
    return null;
  }

  Duration? get serviceDuration {
    final start = serviceStartedAt;
    final end = serviceCompletedAt;
    if (start == null || end == null) return null;
    return end.difference(start);
  }
}

class StatusHistoryModel {
  final String status;
  final String? note;
  final DateTime createdAt;

  const StatusHistoryModel({
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) =>
      StatusHistoryModel(
        status: json['status'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
