import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class WalletRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  WalletRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWallet() => _resolve(
        () => _api.get<Map<String, dynamic>>('/api/v1/wallet'),
        () => DevDataStore.instance.getWallet(),
      );

  Future<Map<String, dynamic>> getReferrals() => _resolve(
        () => _api.get<Map<String, dynamic>>('/api/v1/referrals'),
        () => DevDataStore.instance.getReferrals(),
      );

  Future<Map<String, dynamic>> getEarnings() => _resolve(
        () => _api.get<Map<String, dynamic>>('/api/v1/earnings'),
        () => DevDataStore.instance.getEarnings(),
      );

  Future<List<dynamic>> getNotifications() => _resolve(
        () => _api.get<List<dynamic>>('/api/v1/notifications'),
        () => DevDataStore.instance.getNotifications(),
      );

  Future<void> markNotificationRead(String id) => _resolve(
        () => _api.patch('/api/v1/notifications/$id/read'),
        () => DevDataStore.instance.markNotificationRead(id),
      );

  Future<Map<String, dynamic>> addWalletMoney(double amount, {String method = 'upi'}) => _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>(
            '/api/v1/wallet/top-up',
            data: {'amount': amount, 'method': method},
          );
          return data;
        },
        () {
          DevDataStore.instance.addWalletMoney(amount, method: method);
          return DevDataStore.instance.getWallet();
        },
      );
}
