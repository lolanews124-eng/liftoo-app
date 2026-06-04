import '../../../core/network/api_client.dart';
import '../../../shared/models/assistant_verification_model.dart';

class AssistantVerificationRepository {
  final ApiClient _api;

  AssistantVerificationRepository(this._api, _);

  Future<VerificationBundleModel> getVerification() async {
    final data = await _api.get<Map<String, dynamic>>('/api/v1/assistants/verification');
    return VerificationBundleModel.fromJson(data);
  }

  Future<VerificationBundleModel> submitDocument({
    required VerificationDocType type,
    String? fileUrl,
    String? textValue,
    Map<String, dynamic>? metadata,
  }) async {
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
  }
}
