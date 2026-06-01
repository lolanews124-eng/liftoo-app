import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/address_model.dart';

class AddressesRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AddressesRepository(this._api, this._storage);

  Future<T> _resolve<T>(Future<T> Function() api, T Function() mock) async {
    if (await devIsMockSession(_storage)) return mock();
    try {
      return await api();
    } catch (e) {
      if (DevDataStore.enabled && devShouldUseMock(e)) return mock();
      rethrow;
    }
  }

  Future<List<AddressModel>> getAddresses() => _resolve(
        () async {
          final data = await _api.get<List<dynamic>>('/api/v1/users/addresses');
          return data.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
        },
        () => DevDataStore.instance.getAddresses(),
      );

  Future<AddressModel> createAddress({
    required String label,
    required String formattedAddress,
    required double lat,
    required double lng,
    bool isDefault = false,
  }) =>
      _resolve(
        () async {
          final data = await _api.post<Map<String, dynamic>>('/api/v1/users/addresses', data: {
            'label': label,
            'formattedAddress': formattedAddress,
            'lat': lat,
            'lng': lng,
            'isDefault': isDefault,
          });
          return AddressModel.fromJson(data);
        },
        () => DevDataStore.instance.addAddress(label, formattedAddress, lat, lng, isDefault),
      );

  Future<void> deleteAddress(String id) => _resolve(
        () => _api.delete('/api/v1/users/addresses/$id'),
        () => DevDataStore.instance.deleteAddress(id),
      );

  Future<void> setDefault(String id) => _resolve(
        () => _api.post('/api/v1/users/addresses/$id/default'),
        () => DevDataStore.instance.setDefaultAddress(id),
      );
}
