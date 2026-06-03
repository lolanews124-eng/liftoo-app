import 'package:dio/dio.dart';
import '../network/network_errors.dart';
import '../storage/token_storage.dart';

bool devIsConnectionError(Object e) => NetworkErrors.isOffline(e);

bool devShouldUseMock(Object e) =>
    const bool.fromEnvironment('DEV_MOCK_AUTH', defaultValue: false) && devIsConnectionError(e);

Future<bool> devIsMockSession(TokenStorage storage) async {
  final token = await storage.getAccessToken();
  return token != null && token.startsWith('dev-mock-');
}
