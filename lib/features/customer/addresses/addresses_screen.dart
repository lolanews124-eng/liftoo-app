import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/service_location_model.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../shared/widgets/empty_state.dart';
import '../home/location_picker_sheet.dart';
import '../../../shared/widgets/liftoo_map_view.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/models/address_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(addressesRepositoryProvider).getAddresses();
      if (mounted) setState(() => _addresses = list);
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrors.userMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAddress() async {
    ServiceLocationModel? picked;
    try {
      picked = await showLocationPicker(context, ref, null, savedLocations: const []);
    } catch (_) {}

    if (!mounted || picked == null) return;
    final location = picked;

    final labelCtrl = TextEditingController(text: location.name);
    final addrCtrl = TextEditingController(text: location.address);
    final lat = location.lat;
    final lng = location.lng;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add address'),
        contentPadding: keyboardInsetPadding(ctx, base: const EdgeInsets.fromLTRB(24, 20, 24, 0)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiftooMapView(
                lat: lat,
                lng: lng,
                title: location.displayName,
                height: 140,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                scrollPadding: keyboardScrollPadding(ctx),
                decoration: const InputDecoration(labelText: 'Label (Home, Work…)'),
              ),
              TextField(
                controller: addrCtrl,
                scrollPadding: keyboardScrollPadding(ctx),
                decoration: const InputDecoration(labelText: 'Full address'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || labelCtrl.text.trim().isEmpty || addrCtrl.text.trim().isEmpty) return;

    await ref.read(addressesRepositoryProvider).createAddress(
          label: labelCtrl.text.trim(),
          formattedAddress: addrCtrl.text.trim(),
          lat: lat,
          lng: lng,
          isDefault: _addresses.isEmpty,
        );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      body: _loading
          ? const ListScreenSkeleton(count: 3)
          : _error != null
              ? NetworkErrorState(
                  message: _error,
                  offline: _error == NetworkErrors.noInternet,
                  onRetry: _load,
                )
              : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_addresses.isEmpty)
                    EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No saved addresses',
                      subtitle: 'Add one to book faster',
                      actionLabel: 'Add address',
                      onAction: _addAddress,
                    )
                  else
                    ..._addresses.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LiftooCard(
                            child: Row(
                              children: [
                                Icon(a.isDefault ? Icons.star : Icons.location_on_outlined, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(a.formattedAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (!a.isDefault)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await ref.read(addressesRepositoryProvider).deleteAddress(a.id);
                                      _load();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 16),
                  GradientButton(label: 'Add new address', onPressed: _addAddress),
                ],
              ),
            ),
    );
  }
}
