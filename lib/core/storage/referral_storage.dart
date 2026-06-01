import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReferralStorage {
  static const _key = 'pending_referral_code';
  final _storage = const FlutterSecureStorage();

  Future<void> savePendingCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    await _storage.write(key: _key, value: trimmed);
  }

  Future<String?> consumePendingCode() async {
    final code = await _storage.read(key: _key);
    if (code != null) await _storage.delete(key: _key);
    return code;
  }

  Future<String?> peekPendingCode() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);
}
