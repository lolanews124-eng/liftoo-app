import '../../../core/network/network_errors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/dev/dev_data_store.dart';
import 'dev_auth_mock.dart';
import 'login_result.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;
  final SocketService _socket;

  AuthRepository(this._api, this._storage, this._socket);

  bool _isConnectionError(Object e) => NetworkErrors.isOffline(e);

  bool _isMockSession(String? token) =>
      token != null && token.startsWith('dev-mock-');

  String _mockKey(String email) => email.trim().toLowerCase().replaceAll('@', '-at-');

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
    try {
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
    } catch (e) {
      if (DevAuthMock.isEnabled && _isConnectionError(e)) {
        if (DevAuthMock.isEmailVerified(email)) {
          return _mockDirectLogin(email);
        }
        return const LoginResult(requiresOtp: true);
      }
      rethrow;
    }
  }

  Future<LoginResult> _mockDirectLogin(String email) async {
    final result = DevAuthMock.verify(email);
    final key = _mockKey(email);
    await _storage.saveTokens(
      accessToken: 'dev-mock-$key',
      refreshToken: 'dev-refresh-$key',
    );
    final token = await _storage.getAccessToken();
    if (token != null) _socket.connect(token);
    return LoginResult(requiresOtp: false, user: result.user, isNewUser: false);
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
    try {
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
    } catch (e) {
      if (DevAuthMock.isEnabled &&
          _isConnectionError(e) &&
          DevAuthMock.isValidOtp(otp)) {
        return _mockVerify(email);
      }
      rethrow;
    }
  }

  Future<({UserModel user, bool isNew})> _mockVerify(String email) async {
    final result = DevAuthMock.verify(email);
    final key = _mockKey(email);
    await _storage.saveTokens(
      accessToken: 'dev-mock-$key',
      refreshToken: 'dev-refresh-$key',
    );
    final token = await _storage.getAccessToken();
    if (token != null) _socket.connect(token);
    return result;
  }

  Future<UserModel> completeProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final token = await _storage.getAccessToken();
    if (_isMockSession(token)) {
      final key = token!.replaceFirst('dev-mock-', '');
      DevDataStore.instance.saveUserProfile(
        key,
        name: name,
        phone: phone ?? DevDataStore.instance.getUserProfile(key)?['phone'] as String? ?? '9000000000',
        avatarUrl: avatarUrl,
      );
      final role = await _storage.getRole();
      return DevAuthMock.userFromToken(token, role: role);
    }
    try {
      final data = await _api.put<Map<String, dynamic>>('/api/v1/users/me', data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
      return UserModel.fromJson(data);
    } catch (e) {
      if (DevAuthMock.isEnabled && _isConnectionError(e) && token != null) {
        final key = token.replaceFirst('dev-mock-', '');
        DevDataStore.instance.saveUserProfile(
          key,
          name: name,
          phone: phone ?? DevDataStore.instance.getUserProfile(key)?['phone'] as String? ?? '9000000000',
          avatarUrl: avatarUrl,
        );
        return DevAuthMock.userFromToken(token, role: await _storage.getRole());
      }
      rethrow;
    }
  }

  Future<UserModel> setRole(AppRole role) async {
    final token = await _storage.getAccessToken();
    if (_isMockSession(token)) {
      await _storage.saveRole(role.name);
      return DevAuthMock.userFromToken(token!, role: role.name);
    }

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

    if (_isMockSession(token)) {
      final role = await _storage.getRole();
      return DevAuthMock.userFromToken(token, role: role);
    }

    _socket.connect(token);
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/users/me');
      return UserModel.fromJson(data);
    } catch (e) {
      if (DevAuthMock.isEnabled && _isConnectionError(e) && token.startsWith('dev-mock-')) {
        final role = await _storage.getRole();
        return DevAuthMock.userFromToken(token, role: role);
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _setAssistantOfflineBeforeClear();
    _socket.disconnect();
    await _storage.clear();
  }

  /// So customers do not see ghost "online" assistants after logout or uninstall.
  Future<void> _setAssistantOfflineBeforeClear() async {
    try {
      final role = await _storage.getRole();
      if (role != 'assistant') return;
      await _api.post('/api/v1/assistants/online', data: {'isOnline': false});
    } catch (_) {}
  }
}
