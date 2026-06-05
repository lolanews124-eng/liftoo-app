import '../../../core/network/network_errors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user_model.dart';
import 'login_result.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;
  final SocketService _socket;

  AuthRepository(this._api, this._storage, this._socket);

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    if (user.activeRole != null) {
      await _storage.saveRole(user.activeRole!);
    }
    final token = await _storage.getAccessToken();
    if (token != null) _socket.connect(token);
  }

  Future<LoginResult> loginWithEmail(String email, String password) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/auth/login', data: {
      'email': email.trim(),
      'password': password,
    });
    if (data['requiresOtp'] == false && data['accessToken'] != null) {
      await _persistSession(data);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return LoginResult(requiresOtp: false, user: user, isNewUser: data['isNewUser'] as bool? ?? false);
    }
    return const LoginResult(requiresOtp: true);
  }

  Future<void> resendEmailOtp(String email, String password) async {
    await _api.post('/api/v1/auth/otp/resend', data: {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<({UserModel user, bool isNew})> verifyEmailOtp(
    String email,
    String otp, {
    String? referralCode,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/otp/verify',
      data: {
        'email': email.trim(),
        'otp': otp,
        if (referralCode != null) 'referralCode': referralCode,
      },
    );
    await _persistSession(data);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (user: user, isNew: data['isNewUser'] as bool? ?? false);
  }

  Future<UserModel> completeProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = await _api.put<Map<String, dynamic>>('/api/v1/users/me', data: {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return UserModel.fromJson(data);
  }

  Future<UserModel> setRole(AppRole role) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/role',
      data: {'role': role.name},
    );
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _storage.saveRole(role.name);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final newToken = await _storage.getAccessToken();
    if (newToken != null) _socket.connect(newToken);
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    _socket.connect(token);
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/users/me');
      return UserModel.fromJson(data);
    } catch (e) {
      if (NetworkErrors.isOffline(e)) rethrow;
      return null;
    }
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await _api.post('/api/v1/auth/password/forgot', data: {
      'email': email.trim(),
    });
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post('/api/v1/auth/password/reset', data: {
      'email': email.trim(),
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _setAssistantOfflineBeforeClear();
    _socket.disconnect();
    await _storage.clear();
  }

  Future<void> _setAssistantOfflineBeforeClear() async {
    try {
      final role = await _storage.getRole();
      if (role != 'assistant') return;
      await _api.post('/api/v1/assistants/online', data: {'isOnline': false});
    } catch (_) {}
  }
}
