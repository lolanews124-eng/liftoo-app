import '../../../core/network/api_client.dart';

class PayoutsRepository {
  final ApiClient _api;

  PayoutsRepository(this._api, _);

  Future<Map<String, dynamic>> getBalance() =>
      _api.get<Map<String, dynamic>>('/api/v1/payouts/balance');

  Future<List<dynamic>> getRequests() => _api.get<List<dynamic>>('/api/v1/payouts');

  Future<Map<String, dynamic>> requestPayout(double amount) =>
      _api.post<Map<String, dynamic>>('/api/v1/payouts/request', data: {'amount': amount});
}
