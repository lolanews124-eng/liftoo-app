import '../../../core/network/api_client.dart';
import '../../../shared/models/address_model.dart';

class AddressesRepository {
  final ApiClient _api;

  AddressesRepository(this._api, _);

  Future<List<AddressModel>> getAddresses() async {
    final data = await _api.get<List<dynamic>>('/api/v1/users/addresses');
    return data.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AddressModel> createAddress({
    required String label,
    required String formattedAddress,
    required double lat,
    required double lng,
    bool isDefault = false,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/api/v1/users/addresses', data: {
      'label': label,
      'formattedAddress': formattedAddress,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
    });
    return AddressModel.fromJson(data);
  }

  Future<void> deleteAddress(String id) => _api.delete('/api/v1/users/addresses/$id');

  Future<void> setDefault(String id) => _api.post('/api/v1/users/addresses/$id/default');
}
