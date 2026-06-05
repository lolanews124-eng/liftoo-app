import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingAuthStorage {
  static const _key = 'pending_login_auth';
  final _storage = const FlutterSecureStorage();

  Future<void> saveLoginAuth({required String email, required String password}) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({'email': email.trim(), 'password': password}),
    );
  }

  Future<({String email, String password})?> peekLoginAuth() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final email = map['email'] as String?;
      final password = map['password'] as String?;
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLoginAuth() => _storage.delete(key: _key);
}
