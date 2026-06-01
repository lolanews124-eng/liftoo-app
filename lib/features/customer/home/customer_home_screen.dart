import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location_service.dart';
import '../../../core/dev/dev_data_store.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/service_location_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/hero_assistant.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'home_sheets.dart';
import 'quick_book_draft.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  List<ServiceCategoryModel> _categories = [];
  BookingModel? _activeBooking;
  int _notifCount = 0;
  bool _loading = true;

  ServiceLocationModel? _selectedLocation;
  List<ServiceLocationModel> _savedLocations = [];
  bool _locationLoading = true;
  String _service = 'Bag Carry';
  String? _categorySlug = 'bag_carry';
  int _durationMin = 60;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _load();
    _initLocation();
  }

  String get _locationLabel {
    if (_locationLoading) return 'Getting location…';
    return _selectedLocation?.displayName ?? 'Current location';
  }

  QuickBookDraft get _draft => QuickBookDraft(
        categorySlug: _categorySlug,
        locationId: _selectedLocation?.id,
        venueName: _selectedLocation?.displayName,
        lat: _selectedLocation?.lat,
        lng: _selectedLocation?.lng,
        durationMin: _durationMin,
      );

  Future<void> _initLocation() async {
    await _loadAddresses();
    final gps = await LocationService.resolveCurrentLocation();
    if (mounted) {
      setState(() {
        _selectedLocation = gps;
        _locationLoading = false;
      });
      _loadAvailabilitySummary(gps.lat, gps.lng);
    }
  }

  Future<void> _loadAvailabilitySummary(double lat, double lng) async {
    try {
      final summary = await ref.read(bookingRepositoryProvider).getAvailabilitySummary(lat: lat, lng: lng);
      if (mounted) {
        setState(() => _availabilityMessage = summary['message'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _loadAddresses() async {
    try {
      final addrs = await ref.read(addressesRepositoryProvider).getAddresses();
      if (mounted) {
        setState(() => _savedLocations = addrs.map((a) => a.toServiceLocation()).toList());
      }
    } catch (_) {}
  }

  String get _durationLabel => BookingDurationOptions.labelFor(_durationMin);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);
      final results = await Future.wait([
        bookingRepo.getCategories(),
        bookingRepo.getBookings(status: 'upcoming'),
        walletRepo.getNotifications(),
      ]);
      final cats = results[0] as List<ServiceCategoryModel>;
      final bookings = results[1] as List<BookingModel>;
      final notifs = results[2];
      if (mounted) {
        setState(() {
          _categories = cats;
          if (cats.isNotEmpty && _categorySlug == null) {
            _categorySlug = cats.first.slug;
            _service = _shortName(cats.first.name);
          }
          _activeBooking = bookings.isNotEmpty ? bookings.first : null;
          _notifCount = (notifs as List).where((n) => (n as Map)['readAt'] == null).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        DevDataStore.instance.ensureSeeded();
        setState(() {
          _categories = DevDataStore.categories;
          _activeBooking = DevDataStore.instance.getActiveBooking();
          _notifCount = DevDataStore.instance.unreadNotificationCount;
          _loading = false;
        });
      }
    }
  }

  String _shortName(String name) {
    if (name.contains('Bag')) return 'Bag Carry';
    if (name.contains('Queue')) return 'Queue';
    if (name.contains('Senior')) return 'Senior Help';
    if (name.contains('Family')) return 'Family';
    if (name.contains('Festival')) return 'Festival';
    return name.split(' ').take(2).join(' ');
  }

  void _openBooking([QuickBookDraft? draft]) {
    context.push('/customer/booking', extra: draft ?? _draft);
  }

  void _selectService(ServiceCategoryModel c, {bool openBooking = true}) {
    setState(() {
      _categorySlug = c.slug;
      _service = _shortName(c.name);
    });
    if (openBooking) _openBooking(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final wallet = user?.walletBalance ?? DevDataStore.instance.walletBalance;
    final name = user?.name?.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const HomeScreenSkeleton()
            : Column(
                children: [
                  ColoredBox(
                    color: AppColors.surface,
                    child: _buildTopBar(name, wallet),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _buildHeroBanner(),
                          _buildCategoriesSection(),
                          _buildPopularVenues(),
                          _buildQuickBookCard(),
                          if (_activeBooking != null) _buildActiveBooking(_activeBooking!),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar(String name, double wallet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $name 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(
                  'Where are you shopping today?',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          _iconBtn(Icons.search, onTap: () => context.push('/customer/search')),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.notifications_outlined,
            badge: _notifCount > 0 ? '$_notifCount' : null,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/customer/wallet'),
            child: _walletChip(wallet),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {String? badge, VoidCallback? onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: AppColors.charcoal),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _walletChip(double wallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.charcoal, Color(0xFF2D2D2D)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${wallet.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          Text('Wallet', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(right: 0, bottom: 0, child: HeroAssistantIllustration()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('⚡ Instant booking', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(height: 10),
                  if (_availabilityMessage != null && _availabilityMessage!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _availabilityMessage!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Shop without\ncarrying bags',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 210,
                    child: Text(
                      'Verified assistants for malls, markets & exhibitions.',
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), fontSize: 12, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openBooking(),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Book Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final items = _categories.isNotEmpty ? _categories : DevDataStore.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Services', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              TextButton(onPressed: () => _openBooking(), child: const Text('View all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              final selected = _categorySlug == c.slug;
              final color = AppColors.categoryColor(c.slug);
              final label = _shortName(c.name);
              return GestureDetector(
                onTap: () => _selectService(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 96,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: selected ? 0.28 : 0.18),
                        color.withValues(alpha: selected ? 0.12 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? color : color.withValues(alpha: 0.25), width: selected ? 2 : 1),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: selected ? 0.18 : 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_iconFor(c.slug), color: color, size: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : AppColors.charcoal,
                        ),
                      ),
                      Text(
                        '₹${c.baseRate.toInt()}/hr',
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularVenues() {
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          avatar: const Icon(Icons.my_location, size: 16),
          label: Text(
            _selectedLocation?.isCurrentLocation == true ? 'Current location' : 'Use GPS',
            style: TextStyle(
              fontWeight: _selectedLocation?.isCurrentLocation == true ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          selected: _selectedLocation?.isCurrentLocation == true,
          onSelected: (_) async {
            setState(() => _locationLoading = true);
            final gps = await LocationService.resolveCurrentLocation();
            if (mounted) {
              setState(() {
                _selectedLocation = gps;
                _locationLoading = false;
              });
              _loadAvailabilitySummary(gps.lat, gps.lng);
            }
          },
          selectedColor: AppColors.primaryLight,
          checkmarkColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _selectedLocation?.isCurrentLocation == true ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
      ),
      ..._savedLocations.take(4).map((loc) {
        final selected = _selectedLocation?.id == loc.id;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(loc.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
            selected: selected,
            onSelected: (_) => setState(() => _selectedLocation = loc),
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade200),
          ),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('Pickup near you', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: chips,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickBookCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Quick Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('From ₹49', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _quickField(Icons.location_on_outlined, 'Location', _locationLabel, () async {
                  final picked = await showLocationPicker(context, ref, _selectedLocation, savedLocations: _savedLocations);
                  if (picked != null) {
                    setState(() => _selectedLocation = picked);
                    _loadAvailabilitySummary(picked.lat, picked.lng);
                  }
                })),
                const SizedBox(width: 10),
                Expanded(child: _quickField(Icons.shopping_bag_outlined, 'Service', _service, () => _openBooking(_draft))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _quickField(Icons.timer_outlined, 'Duration', _durationLabel, () async {
                  final picked = await showDurationPicker(context, _durationMin);
                  if (picked != null) setState(() => _durationMin = picked);
                })),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(label: 'Find Assistant', icon: Icons.arrow_forward, onPressed: () => _openBooking(_draft), radius: 14),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _trustChip(Icons.verified_user_outlined, 'Verified'),
                _trustChip(Icons.access_time, 'On-time'),
                _trustChip(Icons.shield_outlined, 'Secure'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickField(IconData icon, String label, String value, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActiveBooking(BookingModel b) {
    final statusLabel = switch (b.status) {
      'arriving' || 'assigned' => 'On the way',
      'searching' => 'Finding assistant',
      'started' => 'In progress',
      _ => b.status,
    };
    final assistantName = b.assistant?['name'] ?? 'Assistant';
    final profile = b.assistant?['assistantProfile'] as Map<String, dynamic>?;
    final rating = (profile?['rating'] as num?)?.toDouble() ?? 4.9;
    final totalJobs = (profile?['totalJobs'] as num?)?.toInt() ?? 0;
    final assistantPhone = b.assistant?['phone'] as String? ?? '9876543211';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Active Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(assistantName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assistantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(
                        b.assistant != null
                            ? '★ ${rating.toStringAsFixed(1)} • $totalJobs jobs • ${b.category?.name ?? "Service"}'
                            : 'Matching best assistant...',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text('📍 ${b.venueName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/customer/booking/${b.id}'),
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Track Live'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.charcoal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: b.assistant != null ? () => callAssistant(assistantPhone) : null,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.charcoal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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
}
