import '../../../core/dev/dev_data_store.dart';
import '../../customer/booking/booking_flow_cache.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/nearby_assistant_model.dart';
import '../../../shared/models/review_models.dart';

class BookingRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  BookingRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<List<ServiceCategoryModel>> getCategories() => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/categories');
          return data.map((e) => ServiceCategoryModel.fromJson(e)).toList();
        },
        () {
          DevDataStore.instance.ensureSeeded();
          return DevDataStore.categories;
        },
      );

  Future<List<NearbyAssistantModel>> getNearbyAssistants({required double lat, required double lng}) => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/assistants/nearby', query: {'lat': lat, 'lng': lng});
          return data
              .map((e) => NearbyAssistantModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((a) => a.hasCoordinates)
              .toList();
        },
        () => DevDataStore.instance
            .getNearbyAssistants(lat, lng)
            .map((e) => NearbyAssistantModel.fromJson(e))
            .toList(),
      );

  Future<BookingModel> createBooking(Map<String, dynamic> body) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings', data: body);
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.createBooking(body),
      );

  Future<BookingModel> confirmBooking(String id) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/confirm');
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.confirmBooking(id),
      );

  Future<List<BookingModel>> getBookings({String? status, String? asRole}) => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/bookings', query: {
            if (status != null) 'status': status,
            if (asRole != null) 'as': asRole,
          });
          return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
        },
        () => DevDataStore.instance.getBookings(status: status, asRole: asRole),
      );

  Future<List<BookingModel>> getNearbyRequests() => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/bookings/nearby');
          return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
        },
        () => DevDataStore.instance.getBookings(status: 'searching'),
      );

  Future<BookingModel?> getCustomerBlockingBooking() => _resolve(
        () async {
          try {
            final data = await _api.get<Map<String, dynamic>?>('/api/v1/bookings/blocking');
            if (data == null) return null;
            return BookingModel.fromJson(data);
          } catch (_) {
            return null;
          }
        },
        () => DevDataStore.instance.getCustomerBlockingBooking(),
      );

  Future<BookingModel?> getActiveJob() => _resolve(
        () async {
          try {
            final data = await _api.get<Map<String, dynamic>>('/api/v1/bookings/active-job');
            return BookingModel.fromJson(data);
          } catch (_) {
            return null;
          }
        },
        () => DevDataStore.instance.getAssistantBlockingJob(),
      );

  Future<BookingModel> getBooking(String id) => _resolve(
        () async {
          final data = await _api.get<Map<String, dynamic>>('/api/v1/bookings/$id');
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.getBooking(id),
      );

  Future<BookingModel> acceptBooking(String id) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/accept');
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.acceptBooking(id),
      );

  Future<void> rejectBooking(String id, {required String reason}) => _resolve(
        () => _api.post('/api/v1/bookings/$id/reject', data: {'reason': reason}),
        () => DevDataStore.instance.rejectBooking(id, reason: reason),
      );

  Future<Map<String, dynamic>> getAvailabilitySummary({required double lat, required double lng}) =>
      _resolve(
        () => _api.get<Map<String, dynamic>>('/api/v1/assistants/availability-summary', query: {
          'lat': lat,
          'lng': lng,
        }),
        () => DevDataStore.instance.getAvailabilitySummary(lat, lng),
      );

  Future<void> updateAssistantLocation({required double lat, required double lng}) => _resolve(
        () => _api.patch('/api/v1/assistants/location', data: {'lat': lat, 'lng': lng}),
        () => DevDataStore.instance.updateAssistantLocation(lat, lng),
      );

  Future<BookingModel> setArriving(String id) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/arriving');
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.setArriving(id),
      );

  Future<BookingModel> verifyOtp(String id, String otp) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>(
            '/api/v1/bookings/$id/otp/verify',
            data: {'otp': otp},
          );
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.verifyServiceOtp(id, otp),
      );

  Future<({BookingModel booking, double? assistantEarning, bool requiresPayment})> completeBooking(String id) =>
      _resolve(
        () async {
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
        },
        () {
          final b = DevDataStore.instance.completeService(id);
          return (
            booking: b,
            assistantEarning: b.assistantEarningAmount ?? b.serviceFee * 0.8,
            requiresPayment: true,
          );
        },
      );

  Future<BookingModel> cancelBooking(String id, {required String reason, String? note}) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>(
            '/api/v1/bookings/$id/cancel',
            data: {'reason': reason, if (note != null) 'note': note},
          );
          return BookingModel.fromJson(data);
        },
        () => DevDataStore.instance.cancelBooking(id, reason: reason, note: note),
      );

  Future<void> setOnline(bool isOnline, {double? lat, double? lng}) => _resolve(
        () => _api.post('/api/v1/assistants/online', data: {
          'isOnline': isOnline,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        }),
        () => DevDataStore.instance.setAssistantOnline(isOnline, lat: lat, lng: lng),
      );

  Future<PaymentResultModel> payBooking(String id, String method) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$id/pay', data: {'method': method});
          BookingFlowCache.instance.markPaid(id);
          return PaymentResultModel.fromJson(data);
        },
        () {
          BookingFlowCache.instance.markPaid(id);
          return DevDataStore.instance.payBooking(id, method);
        },
      );

  Future<BookingModel> markCashCollected(String bookingId) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/bookings/$bookingId/cash/collect');
          final bookingJson = data['booking'] is Map
              ? Map<String, dynamic>.from(data['booking'] as Map)
              : Map<String, dynamic>.from(data);
          return BookingModel.fromJson(bookingJson);
        },
        () => DevDataStore.instance.markCashCollected(bookingId),
      );

  Future<PaymentResultModel> confirmCashPayment(String bookingId, String otp) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>(
            '/api/v1/bookings/$bookingId/cash/confirm',
            data: {'otp': otp},
          );
          BookingFlowCache.instance.markPaid(bookingId);
          return PaymentResultModel.fromJson(data);
        },
        () {
          BookingFlowCache.instance.markPaid(bookingId);
          return DevDataStore.instance.confirmCashPayment(bookingId, otp);
        },
      );
}
