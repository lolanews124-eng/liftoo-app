import '../../customer/booking/booking_flow_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/nearby_assistant_model.dart';
import '../../../shared/models/review_models.dart';

class BookingRepository {
  final ApiClient _api;

  BookingRepository(this._api, _);

  Future<List<ServiceCategoryModel>> getCategories() async {
    final data = await _api.get<List<dynamic>>('/api/v1/categories');
    return data.map((e) => ServiceCategoryModel.fromJson(e)).toList();
  }

  Future<List<NearbyAssistantModel>> getNearbyAssistants({required double lat, required double lng}) async {
    final data = await _api.get<List<dynamic>>('/api/v1/assistants/nearby', query: {'lat': lat, 'lng': lng});
    return data
        .map((e) => NearbyAssistantModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((a) => a.hasCoordinates)
        .toList();
  }

  Future<BookingModel> createBooking(Map<String, dynamic> body) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings', data: body);
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> confirmBooking(String id) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/confirm');
    return BookingModel.fromJson(data);
  }

  Future<List<BookingModel>> getBookings({String? status, String? asRole}) async {
    final data = await _api.get<List<dynamic>>('/api/v1/bookings', query: {
      if (status != null) 'status': status,
      if (asRole != null) 'as': asRole,
    });
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BookingModel>> getNearbyRequests() async {
    final data = await _api.get<List<dynamic>>('/api/v1/bookings/nearby');
    return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel?> getCustomerBlockingBooking() async {
    try {
      final data = await _api.get<Map<String, dynamic>?>('/api/v1/bookings/blocking');
      if (data == null) return null;
      return BookingModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel?> getActiveJob() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/bookings/active-job');
      return BookingModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel> getBooking(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/v1/bookings/$id');
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> acceptBooking(String id) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/accept');
    return BookingModel.fromJson(data);
  }

  Future<void> rejectBooking(String id, {required String reason}) =>
      _api.post('/api/v1/bookings/$id/reject', data: {'reason': reason});

  Future<Map<String, dynamic>> getAvailabilitySummary({required double lat, required double lng}) =>
      _api.get<Map<String, dynamic>>('/api/v1/assistants/availability-summary', query: {
        'lat': lat,
        'lng': lng,
      });

  Future<void> updateAssistantLocation({required double lat, required double lng}) =>
      _api.patch('/api/v1/assistants/location', data: {'lat': lat, 'lng': lng});

  Future<BookingModel> setArriving(String id) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/arriving');
    return BookingModel.fromJson(data);
  }

  Future<BookingModel> verifyOtp(String id, String otp) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/bookings/$id/otp/verify',
      data: {'otp': otp},
    );
    return BookingModel.fromJson(data);
  }

  Future<({BookingModel booking, double? assistantEarning, bool requiresPayment})> completeBooking(
    String id,
  ) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/complete');
    final bookingJson = data['booking'] is Map
        ? Map<String, dynamic>.from(data['booking'] as Map)
        : Map<String, dynamic>.from(data);
    if (data['paymentConfirmOtp'] != null) {
      bookingJson['paymentConfirmOtp'] = data['paymentConfirmOtp'];
    }
    if (data['assistantEarning'] != null) {
      bookingJson['assistantEarningAmount'] = data['assistantEarning'];
    }
    if (data['companyShareAmount'] != null) {
      bookingJson['companyShareAmount'] = data['companyShareAmount'];
    }
    return (
      booking: BookingModel.fromJson(bookingJson),
      assistantEarning: (data['assistantEarning'] as num?)?.toDouble(),
      requiresPayment: data['requiresPayment'] == true,
    );
  }

  Future<BookingModel> cancelBooking(String id, {required String reason, String? note}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/bookings/$id/cancel',
      data: {'reason': reason, if (note != null) 'note': note},
    );
    return BookingModel.fromJson(data);
  }

  Future<void> setOnline(bool isOnline, {double? lat, double? lng}) =>
      _api.post('/api/v1/assistants/online', data: {
        'isOnline': isOnline,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

  Future<PaymentResultModel> payBooking(String id, String method) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/pay', data: {'method': method});
    BookingFlowCache.instance.markPaid(id);
    return PaymentResultModel.fromJson(data);
  }

  Future<BookingModel> markCashCollected(String bookingId) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$bookingId/cash/collect');
    final bookingJson = data['booking'] is Map
        ? Map<String, dynamic>.from(data['booking'] as Map)
        : Map<String, dynamic>.from(data);
    return BookingModel.fromJson(bookingJson);
  }

  Future<PaymentResultModel> confirmCashPayment(String bookingId, String otp) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/bookings/$bookingId/cash/confirm',
      data: {'otp': otp},
    );
    BookingFlowCache.instance.markPaid(bookingId);
    return PaymentResultModel.fromJson(data);
  }
}
