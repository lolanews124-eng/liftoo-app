import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_service.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/geocode_models.dart';
import '../../../shared/models/service_location_model.dart';

Future<ServiceLocationModel?> showLocationPicker(
  BuildContext context,
  WidgetRef ref,
  ServiceLocationModel? current, {
  List<ServiceLocationModel> savedLocations = const [],
}) {
  return showModalBottomSheet<ServiceLocationModel>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _LocationPickerSheet(
      current: current,
      savedLocations: savedLocations,
      biasLat: current?.lat ?? LocationService.defaultLat,
      biasLng: current?.lng ?? LocationService.defaultLng,
    ),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  final ServiceLocationModel? current;
  final List<ServiceLocationModel> savedLocations;
  final double biasLat;
  final double biasLng;

  const _LocationPickerSheet({
    required this.current,
    required this.savedLocations,
    required this.biasLat,
    required this.biasLng,
  });

  @override
  ConsumerState<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _gpsLoading = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(geocodeRepositoryProvider).autocomplete(
            query: query,
            lat: widget.biasLat,
            lng: widget.biasLng,
          );
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _searchError = 'Search unavailable';
        });
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pickSuggestion(PlaceSuggestion suggestion) async {
    setState(() => _searching = true);
    try {
      final place = await ref.read(geocodeRepositoryProvider).getPlace(suggestion.placeId);
      if (mounted) Navigator.pop(context, place.toServiceLocation(id: suggestion.placeId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load place details')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useGps() async {
    setState(() => _gpsLoading = true);
    final loc = await LocationService.resolveCurrentLocation();
    if (mounted) {
      setState(() => _gpsLoading = false);
      Navigator.pop(context, loc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, scroll) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Choose pickup location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search mall, market, area…',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(_searchError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: _gpsLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('Use current location', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('GPS + server address lookup', style: TextStyle(fontSize: 12)),
                      onTap: _gpsLoading ? null : _useGps,
                    ),
                    if (_suggestions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          'Search results',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      ..._suggestions.map((s) {
                        return ListTile(
                          leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                          title: Text(
                            s.mainText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            s.secondaryText,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _pickSuggestion(s),
                        );
                      }),
                    ],
                    if (widget.savedLocations.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          'Saved addresses',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      ...widget.savedLocations.map((loc) {
                        final selected = widget.current?.id == loc.id;
                        return ListTile(
                          leading: Icon(
                            selected ? Icons.radio_button_checked : Icons.home_outlined,
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          title: Text(loc.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                          subtitle: Text(loc.address, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.pop(context, loc),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
