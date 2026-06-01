import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class SupportRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  SupportRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTickets() => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/support/tickets');
          return data.cast<Map<String, dynamic>>();
        },
        () => DevDataStore.instance.getSupportTickets(),
      );

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String? bookingId,
  }) =>
      _resolve(
        () => _api.post<Map<String, dynamic>>('/api/v1/support/tickets', data: {
          'subject': subject,
          'message': message,
          if (bookingId != null) 'bookingId': bookingId,
        }),
        () => DevDataStore.instance.createSupportTicket(subject, message),
      );
}
