import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class PromosRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  PromosRepository(this._api, this._storage);

  Future<Map<String, dynamic>> validate(String code, double orderAmount) async {
    return _api.post<Map<String, dynamic>>('/api/v1/promos/validate', data: {
      'code': code,
      'orderAmount': orderAmount,
    });
  }

  Future<Map<String, dynamic>> applyToBooking(String bookingId, String code) async {
    return _api.post<Map<String, dynamic>>('/api/v1/promos/bookings/$bookingId/apply', data: {'code': code});
  }
}
