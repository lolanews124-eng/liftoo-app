import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class ChatRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  ChatRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String bookingId) => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/chat/bookings/$bookingId/messages');
          return data.cast<Map<String, dynamic>>();
        },
        () => DevDataStore.instance.getChatMessages(bookingId),
      );

  Future<Map<String, dynamic>> sendMessage(String bookingId, String message) => _resolve(
        () => _api.post<Map<String, dynamic>>('/api/v1/chat/bookings/$bookingId/messages', data: {'message': message}),
        () => DevDataStore.instance.sendChatMessage(bookingId, message),
      );
}
