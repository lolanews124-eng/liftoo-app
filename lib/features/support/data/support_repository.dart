import '../../../core/network/api_client.dart';

class SupportRepository {
  final ApiClient _api;

  SupportRepository(this._api, _);

  Future<List<Map<String, dynamic>>> getTickets() async {
    final data = await _api.get<List<dynamic>>('/api/v1/support/tickets');
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String? bookingId,
  }) =>
      _api.post<Map<String, dynamic>>('/api/v1/support/tickets', data: {
        'subject': subject,
        'message': message,
        if (bookingId != null) 'bookingId': bookingId,
      });
}
