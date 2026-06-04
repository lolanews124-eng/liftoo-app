import '../../../core/network/api_client.dart';

class WalletRepository {
  final ApiClient _api;

  WalletRepository(this._api, _);

  Future<Map<String, dynamic>> getWallet() =>
      _api.get<Map<String, dynamic>>('/api/v1/wallet');

  Future<Map<String, dynamic>> getReferrals() =>
      _api.get<Map<String, dynamic>>('/api/v1/referrals');

  Future<Map<String, dynamic>> getEarnings() =>
      _api.get<Map<String, dynamic>>('/api/v1/earnings');

  Future<List<dynamic>> getNotifications() =>
      _api.get<List<dynamic>>('/api/v1/notifications');

  Future<void> markNotificationRead(String id) =>
      _api.patch('/api/v1/notifications/$id/read');

  Future<void> markAllNotificationsRead() =>
      _api.patch('/api/v1/notifications/read-all');

  Future<void> deleteNotification(String id) =>
      _api.delete('/api/v1/notifications/$id');

  Future<void> deleteAllNotifications() =>
      _api.delete('/api/v1/notifications');

  Future<Map<String, dynamic>> addWalletMoney(double amount, {String method = 'upi'}) =>
      _api.post<Map<String, dynamic>>(
        '/api/v1/wallet/top-up',
        data: {'amount': amount, 'method': method},
      );
}
