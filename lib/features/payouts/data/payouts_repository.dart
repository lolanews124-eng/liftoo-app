import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class PayoutsRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  PayoutsRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBalance() => _resolve(
        () => _api.get<Map<String, dynamic>>('/api/v1/payouts/balance'),
        () => {'available': DevDataStore.instance.totalEarned},
      );

  Future<List<dynamic>> getRequests() => _resolve(
        () => _api.get<List<dynamic>>('/api/v1/payouts'),
        () => [],
      );

  Future<Map<String, dynamic>> requestPayout(double amount) => _resolve(
        () => _api.post<Map<String, dynamic>>('/api/v1/payouts/request', data: {'amount': amount}),
        () => {'id': 'payout-mock', 'amount': amount, 'status': 'pending'},
      );
}
