import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/assistant_verification_model.dart';

class AssistantVerificationRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AssistantVerificationRepository(this._api, this._storage);

  Future<VerificationBundleModel> getVerification() async {
    if (await devIsMockSession(_storage)) {
      return DevDataStore.instance.getVerificationBundle(await _mockUserId());
    }
    try {
      final data = await _api.get<Map<String, dynamic>>('/api/v1/assistants/verification');
      return VerificationBundleModel.fromJson(data);
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) {
        return DevDataStore.instance.getVerificationBundle(await _mockUserId());
      }
      rethrow;
    }
  }

  Future<VerificationBundleModel> submitDocument({
    required VerificationDocType type,
    String? fileUrl,
    String? textValue,
    Map<String, dynamic>? metadata,
  }) async {
    if (await devIsMockSession(_storage)) {
      return DevDataStore.instance.submitVerificationDocument(
        await _mockUserId(),
        type.apiValue,
        fileUrl: fileUrl,
        textValue: textValue,
        metadata: metadata,
      );
    }
    try {
      final data = await _api.post<Map<String, dynamic>>(
        '/api/v1/assistants/verification/submit',
        data: {
          'type': type.apiValue,
          if (fileUrl != null) 'fileUrl': fileUrl,
          if (textValue != null) 'textValue': textValue,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return VerificationBundleModel.fromJson(data);
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) {
        return DevDataStore.instance.submitVerificationDocument(
          await _mockUserId(),
          type.apiValue,
          fileUrl: fileUrl,
          textValue: textValue,
          metadata: metadata,
        );
      }
      rethrow;
    }
  }

  Future<String> _mockUserId() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.startsWith('dev-mock-')) {
      return 'dev-user-${token.replaceFirst('dev-mock-', '')}';
    }
    return 'dev-user-local';
  }
}
