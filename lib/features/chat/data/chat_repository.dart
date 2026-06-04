import '../../../core/network/api_client.dart';

class ChatRepository {
  final ApiClient _api;

  ChatRepository(this._api, _);

  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    final data = await _api.get<List<dynamic>>('/api/v1/chat/bookings/$bookingId/messages');
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendMessage(String bookingId, String message) =>
      _api.post<Map<String, dynamic>>('/api/v1/chat/bookings/$bookingId/messages', data: {'message': message});
}
