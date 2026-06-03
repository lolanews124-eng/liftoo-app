import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location_service.dart';
import '../../../core/router/back_navigation.dart';
import '../../../core/dev/dev_data_store.dart';
import '../../../core/dev/dev_mock.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/booking/booking_block_guard.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/nearby_assistant_model.dart';
import '../../../shared/models/service_location_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'widgets/booking_pickup_map.dart';
import '../../../core/layout/screen_safe_padding.dart';
import '../home/home_sheets.dart';
import '../home/quick_book_draft.dart';

class BookingWizardScreen extends ConsumerStatefulWidget {
  final QuickBookDraft? draft;

  const BookingWizardScreen({super.key, this.draft});

  @override
  ConsumerState<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  int _step = 0;
  Timer? _assistantsLoadDebounce;
  Timer? _nearbyRefreshTimer;
  List<ServiceCategoryModel> _categories = [];
  ServiceCategoryModel? _selectedCategory;
  int _duration = 60;
  ServiceLocationModel? _selectedLocation;
  List<ServiceLocationModel> _savedLocations = [];
  bool _locationLoading = true;
  bool _loading = false;
  bool _assistantsLoading = false;
  bool _gpsRefreshing = false;
  List<NearbyAssistantModel> _nearbyAssistants = [];
  int _matchRadiusKm = 10;

  @override
  void dispose() {
    _assistantsLoadDebounce?.cancel();
    _nearbyRefreshTimer?.cancel();
    super.dispose();
  }

  void _syncNearbyAutoRefresh() {
    _nearbyRefreshTimer?.cancel();
    if (_step == 1 && _selectedLocation != null) {
      _nearbyRefreshTimer = Timer.periodic(const Duration(seconds: 18), (_) {
        if (mounted && _step == 1) unawaited(_loadNearbyAssistants(silent: true));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.draft?.durationMin != null) _duration = widget.draft!.durationMin!;
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardBlockingBooking());
    _loadCategories();
    _initLocation();
  }

  Future<void> _guardBlockingBooking() async {
    final blocking = await ref.read(bookingRepositoryProvider).getCustomerBlockingBooking();
    if (!mounted || blocking == null) return;
    navigateToResolveBlockingBooking(context, blocking);
    if (mounted) context.pop();
  }

  Future<void> _initLocation() async {
    await _loadAddresses();
    final draft = widget.draft;
    if (draft?.locationId != null && draft!.locationId != ServiceLocationModel.currentLocationId) {
      final match = _savedLocations.where((l) => l.id == draft.locationId).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _selectedLocation = match;
          _locationLoading = false;
        });
        return;
      }
    }
    if (draft?.lat != null && draft?.lng != null) {
      final loc = await LocationService.fromCoordinates(draft!.lat!, draft.lng!, isCurrent: false);
      if (mounted) {
        setState(() {
          _selectedLocation = draft.venueName != null && draft.venueName!.trim().isNotEmpty
              ? loc.copyWith(name: draft.venueName!.trim())
              : loc;
          _locationLoading = false;
        });
        return;
      }
    }
    final gps = await LocationService.resolveCurrentLocation();
    if (mounted) {
      setState(() {
        _selectedLocation = gps;
        _locationLoading = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addrs = await ref.read(addressesRepositoryProvider).getAddresses();
      if (!mounted) return;
      final locs = addrs.map((a) => a.toServiceLocation()).toList();
      setState(() {
        _savedLocations = locs;
      });
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(bookingRepositoryProvider).getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        final slug = widget.draft?.categorySlug;
        ServiceCategoryModel? picked;
        if (slug != null) {
          for (final c in cats) {
            if (c.slug == slug) {
              picked = c;
              break;
            }
          }
        }
        _selectedCategory = picked ?? (cats.isNotEmpty ? cats.first : null);
      });
    } catch (_) {
      if (!mounted) return;
      final useMock = await devIsMockSession(ref.read(tokenStorageProvider));
      setState(() {
        if (useMock) {
          _categories = DevDataStore.categories;
          final slug = widget.draft?.categorySlug;
          ServiceCategoryModel? picked;
          if (slug != null) {
            for (final c in _categories) {
              if (c.slug == slug) {
                picked = c;
                break;
              }
            }
          }
          _selectedCategory = picked ?? (_categories.isNotEmpty ? _categories.first : null);
        } else {
          _categories = [];
          _selectedCategory = null;
        }
      });
    }
  }

  double get _serviceFee {
    if (_selectedCategory == null) return 0;
    return _selectedCategory!.baseRate * (_duration / 60);
  }

  double get _platformFee => _serviceFee * 0.1;
  double get _total => _serviceFee + _platformFee;

  String get _locationDisplayName => _selectedLocation?.displayName ?? 'Getting location…';

  Future<void> _confirm() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }
    final loc = _selectedLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please wait for location or pick one')));
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final booking = await repo.createBooking({
        'categoryId': _selectedCategory!.id,
        'durationMin': _duration,
        'venueName': loc.displayName,
        'scheduledAt': DateTime.now().toIso8601String(),
        'addressLabel': loc.name.isNotEmpty ? loc.name : loc.displayName,
        'addressFormatted': loc.address.isNotEmpty ? loc.address : loc.displayName,
        'lat': loc.lat,
        'lng': loc.lng,
      });
      BookingModel active = booking;
      try {
        active = await repo.confirmBooking(booking.id);
      } catch (confirmError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking saved. Retrying search… (${NetworkErrors.userMessage(confirmError)})')),
          );
        }
      }
      if (mounted) context.go('/customer/booking/${active.id}');
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _hasValidLocation => !_locationLoading && _selectedLocation != null;

  List<NearbyAssistantModel> get _nearbyWithinRadius => _nearbyAssistants.where((a) {
        if (!a.hasCoordinates) return false;
        if (a.distanceKm == null) return true;
        return a.distanceKm! <= _matchRadiusKm;
      }).toList();

  bool get _canProceedFromMapStep => !_assistantsLoading && _nearbyWithinRadius.isNotEmpty;

  String get _stepTitle => switch (_step) {
        0 => 'Choose service',
        1 => 'Pickup location',
        2 => 'Review booking',
        _ => 'Confirm & pay',
      };

  void _scheduleLoadNearbyAssistants() {
    _assistantsLoadDebounce?.cancel();
    _assistantsLoadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_loadNearbyAssistants());
    });
  }

  Future<void> _loadNearbyAssistants({bool silent = false}) async {
    final loc = _selectedLocation;
    if (loc == null) return;
    final hadData = _nearbyAssistants.isNotEmpty;
    if (!silent || !hadData) {
      if (!_assistantsLoading) setState(() => _assistantsLoading = true);
    }
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final results = await Future.wait([
        repo.getNearbyAssistants(lat: loc.lat, lng: loc.lng),
        repo.getAvailabilitySummary(lat: loc.lat, lng: loc.lng),
      ]).timeout(const Duration(seconds: 12));
      final assistants = results[0] as List<NearbyAssistantModel>;
      final summary = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _nearbyAssistants = assistants;
        _matchRadiusKm = (summary['matchRadiusKm'] as num?)?.toInt() ?? 10;
        _assistantsLoading = false;
      });
      _syncNearbyAutoRefresh();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        if (!hadData) _nearbyAssistants = [];
        _assistantsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!hadData) _nearbyAssistants = [];
        _assistantsLoading = false;
      });
    }
  }

  void _next() {
    if (_step == 0 && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }
    if (_step == 1) {
      if (!_hasValidLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for location or choose a pickup address')),
        );
        return;
      }
      if (_assistantsLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checking assistants near you…')),
        );
        return;
      }
      if (!_canProceedFromMapStep) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No assistants available right now')),
        );
        return;
      }
    }
    if (_step < 3) {
      final enteringMap = _step == 0;
      setState(() => _step++);
      if (enteringMap) _scheduleLoadNearbyAssistants();
      _syncNearbyAutoRefresh();
    } else {
      _confirm();
    }
  }

  void _previousStep() {
    setState(() => _step--);
    _syncNearbyAutoRefresh();
  }

  void _handleBack() {
    if (_step > 0) {
      _previousStep();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/customer');
    }
  }

  Future<void> _pickLocation() async {
    final picked = await showLocationPicker(context, ref, _selectedLocation, savedLocations: _savedLocations);
    if (picked != null) {
      setState(() => _selectedLocation = picked);
      if (_step == 1) _scheduleLoadNearbyAssistants();
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsRefreshing = true);
    try {
      final gps = await LocationService.resolveCurrentLocation();
      if (!mounted) return;
      setState(() => _selectedLocation = gps);
      if (_step == 1) _scheduleLoadNearbyAssistants();
    } finally {
      if (mounted) setState(() => _gpsRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepBackScope(
      step: _step,
      onStepBack: _previousStep,
      child: Scaffold(
      appBar: AppBar(
        title: Text('$_stepTitle (${_step + 1}/4)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
            minHeight: 4,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: switch (_step) {
                  0 => _buildStep1(),
                  1 => _buildStep2(),
                  2 => _buildStep3(),
                  _ => _buildStep4(),
                },
              ),
            ),
          ),
          if (_selectedCategory != null && _step < 2) _buildPriceBar(),
          SafeBottomBar(
            padding: EdgeInsets.fromLTRB(20, _selectedCategory != null ? 12 : 20, 20, 20),
            child: GradientButton(
              label: _continueButtonLabel,
              isLoading: _loading,
              onPressed: _continueEnabled ? _next : null,
            ),
          ),
        ],
      ),
      ),
    );
  }

  String get _continueButtonLabel {
    if (_step == 3) return 'Confirm Booking';
    if (_step == 1 && !_assistantsLoading && !_canProceedFromMapStep) {
      return 'No assistant available';
    }
    return 'Continue';
  }

  bool get _continueEnabled {
    if (_loading) return false;
    if (_step == 1) return _hasValidLocation && _canProceedFromMapStep;
    return true;
  }

  Widget _buildPriceBar() {
    final durationLabel = BookingDurationOptions.labelFor(_duration);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedCategory!.name} • $durationLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_selectedCategory!.baseRate.toInt()}/hr • $durationLabel',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Service total', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 11)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    '₹${_serviceFee.toStringAsFixed(0)}',
                    key: ValueKey(_serviceFee),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Could not load services', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Check your internet connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _loadCategories, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Select service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((c) => SizedBox(width: itemWidth, child: _serviceBox(c))).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookingDurationOptions.options.map((o) {
            final selected = _duration == o.minutes;
            return ChoiceChip(
              label: Text(o.label),
              selected: selected,
              onSelected: (_) => setState(() => _duration = o.minutes),
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
              side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'You will choose pickup location on the next step',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _serviceBox(ServiceCategoryModel c) {
    final selected = _selectedCategory?.id == c.id;
    final color = AppColors.categoryColor(c.slug);
    final icon = _iconFor(c.slug);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withValues(alpha: selected ? 0.22 : 0.14),
              color.withValues(alpha: selected ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.22), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${c.baseRate.toInt()}/hr',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String slug) => switch (slug) {
        'bag_carry' => Icons.shopping_bag_outlined,
        'queue' => Icons.groups_outlined,
        'family' => Icons.family_restroom_outlined,
        'senior' => Icons.elderly_outlined,
        'festival' => Icons.celebration_outlined,
        _ => Icons.help_outline,
      };

  Widget _buildStep2() {
    if (_locationLoading && _selectedLocation == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final loc = _selectedLocation;
    if (loc == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Location not ready', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use current location'),
              ),
            ],
          ),
        ),
      );
    }
    final onMap = _nearbyWithinRadius;
    final addressLine = loc.city.isNotEmpty ? '${loc.address}, ${loc.city}' : loc.address;

    final onlineCount = onMap.length;

    return ListView(
      key: const PageStorageKey<String>('booking-step-pickup'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        Stack(
          children: [
            BookingPickupMap(
              pickupLat: loc.lat,
              pickupLng: loc.lng,
              pickupTitle: loc.displayName,
              assistants: onMap,
              height: 300,
            ),
            if (_gpsRefreshing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              ),
            Positioned(
              top: 58,
              left: 12,
              right: 12,
              child: _MapOnlineBadge(
                loading: _assistantsLoading,
                count: onlineCount,
                matchRadiusKm: _matchRadiusKm,
                onRetry: _loadNearbyAssistants,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: _pickLocation,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(addressLine, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _gpsRefreshing ? null : _useCurrentLocation,
                icon: _gpsRefreshing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_gpsRefreshing ? 'Updating…' : 'Use GPS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Change'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Booking summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _summaryTile(Icons.category_outlined, 'Service', _selectedCategory?.name ?? '—'),
              const Divider(height: 24),
              _summaryTile(Icons.timer_outlined, 'Duration', BookingDurationOptions.labelFor(_duration)),
              const Divider(height: 24),
              _summaryTile(Icons.store_mall_directory_outlined, 'Location', _locationDisplayName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _trustBadge(Icons.verified_user_outlined, 'Verified assistants'),
            const SizedBox(width: 8),
            _trustBadge(Icons.shield_outlined, 'Secure booking'),
          ],
        ),
      ],
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final color = AppColors.categoryColor(_selectedCategory?.slug ?? '');
    final durationLabel = BookingDurationOptions.labelFor(_duration);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.14), AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Ready to confirm?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Your assistant will be matched shortly after booking',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _confirmDetailRow(Icons.shopping_bag_outlined, 'Service', _selectedCategory?.name ?? '—', color),
              const Divider(height: 20),
              _confirmDetailRow(Icons.timer_outlined, 'Duration', durationLabel, AppColors.primary),
              const Divider(height: 20),
              _confirmDetailRow(Icons.location_on_outlined, 'Location', _locationDisplayName, AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, Color(0xFF002A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.charcoal.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Price breakdown', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              _confirmFeeRow('Service fee', _serviceFee),
              const SizedBox(height: 8),
              _confirmFeeRow('Platform fee (10%)', _platformFee),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white24, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total payable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(
                    '₹${_total.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text('Safe & secure payment after service', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _confirmDetailRow(IconData icon, String label, String value, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confirmFeeRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
        Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

class _MapOnlineBadge extends StatelessWidget {
  final bool loading;
  final int count;
  final int matchRadiusKm;
  final VoidCallback? onRetry;

  const _MapOnlineBadge({
    required this.loading,
    required this.count,
    required this.matchRadiusKm,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Checking assistants…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );
    }

    final available = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: available ? AppColors.successLight.withValues(alpha: 0.95) : const Color(0xFFFEE2E2).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: available ? AppColors.success.withValues(alpha: 0.35) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.person_off_outlined,
            size: 18,
            color: available ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? '$count assistant${count == 1 ? '' : 's'} online within $matchRadiusKm km'
                  : 'No assistants online nearby',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: available ? AppColors.navy : AppColors.error,
              ),
            ),
          ),
          if (!available && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
