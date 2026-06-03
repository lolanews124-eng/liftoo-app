import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location_service.dart';
import '../../../core/dev/dev_data_store.dart';
import '../../../core/realtime/notification_listener.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/booking/booking_block_guard.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/service_location_model.dart';
import '../../../shared/widgets/assistant_info.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'home_sheets.dart';
import 'quick_book_draft.dart';
import 'widgets/home_hero_carousel.dart';
import 'widgets/home_quick_book_card.dart';
import 'widgets/home_referral_banner.dart';
import 'widgets/home_services_strip.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  List<ServiceCategoryModel> _categories = [];
  BookingModel? _blockingBooking;
  int _referralReward = 100;
  bool _loading = true;

  ServiceLocationModel? _selectedLocation;
  List<ServiceLocationModel> _savedLocations = [];
  bool _locationLoading = true;
  String _service = 'Bag Carry';
  String? _categorySlug = 'bag_carry';
  int _durationMin = 60;

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
    }
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
        bookingRepo.getCustomerBlockingBooking(),
        walletRepo.getNotifications(),
        walletRepo.getReferrals(),
      ]);
      final cats = results[0] as List<ServiceCategoryModel>;
      final blocking = results[1] as BookingModel?;
      final notifs = results[2] as List<dynamic>;
      final referralInfo = results[3] as Map<String, dynamic>;
      final reward = (referralInfo['rewardPerReferral'] as num?)?.toInt() ?? 100;
      if (mounted) {
        ref.invalidate(customerBlockingBookingProvider);
        setState(() {
          _categories = cats;
          if (cats.isNotEmpty && _categorySlug == null) {
            _categorySlug = cats.first.slug;
            _service = _shortName(cats.first.name);
          }
          _blockingBooking = blocking;
          _referralReward = reward;
          ref.read(unreadNotificationCountProvider.notifier).state =
              notifs.where((n) => (n as Map)['readAt'] == null).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        DevDataStore.instance.ensureSeeded();
        ref.invalidate(customerBlockingBookingProvider);
        setState(() {
          _categories = DevDataStore.categories;
          _blockingBooking = DevDataStore.instance.getCustomerBlockingBooking();
          _referralReward =
              (DevDataStore.instance.getReferrals()['rewardPerReferral'] as num?)?.toInt() ?? 100;
          ref.read(unreadNotificationCountProvider.notifier).state =
              DevDataStore.instance.unreadNotificationCount;
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
    if (_blockingBooking != null) return;
    context.push('/customer/booking', extra: draft ?? _draft);
  }

  bool get _canBook => _blockingBooking == null;

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
    final notifCount = ref.watch(unreadNotificationCountProvider);
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
                    child: _buildTopBar(name, wallet, notifCount),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 4),
                          HomeHeroCarousel(
                            onBookTap: _canBook ? () => _openBooking() : null,
                          ),
                          if (_canBook) _buildQuickBookSection() else if (_blockingBooking != null) _buildBlockingBooking(_blockingBooking!),
                          _buildCategoriesSection(),
                          HomeReferralBanner(
                            rewardAmount: _referralReward,
                            onTap: () => context.push('/referral'),
                          ),
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

  Widget _buildTopBar(String name, double wallet, int notifCount) {
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
          _iconBtn(
            Icons.search,
            onTap: _canBook ? () => context.push('/customer/search') : null,
          ),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.notifications_outlined,
            badge: notifCount > 0 ? '$notifCount' : null,
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
        gradient: const LinearGradient(colors: [AppColors.navy, Color(0xFF002A5C)]),
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

  Widget _buildQuickBookSection() {
    return HomeQuickBookCard(
      locationLabel: _locationLabel,
      serviceLabel: _service,
      durationLabel: _durationLabel,
      locationLoading: _locationLoading,
      onLocationTap: () async {
        final picked = await showLocationPicker(context, ref, _selectedLocation, savedLocations: _savedLocations);
        if (picked != null) setState(() => _selectedLocation = picked);
      },
      onServiceTap: () => _openBooking(_draft),
      onDurationTap: () async {
        final picked = await showDurationPicker(context, _durationMin);
        if (picked != null) setState(() => _durationMin = picked);
      },
      onFindAssistant: () => _openBooking(_draft),
    );
  }

  Widget _buildCategoriesSection() {
    final items = _categories.isNotEmpty ? _categories : DevDataStore.categories;
    return HomeServicesStrip(
      categories: items,
      selectedSlug: _categorySlug,
      shortName: _shortName,
      iconFor: _iconFor,
      bookingEnabled: _canBook,
      onTap: (c) => _selectService(c, openBooking: _canBook),
      onViewAll: _canBook ? () => _openBooking() : null,
    );
  }

  Widget _buildBlockingBooking(BookingModel b) {
    final statusLabel = b.isPaymentPending
        ? 'Payment due'
        : switch (b.status) {
            'arriving' || 'assigned' => 'On the way',
            'searching' => 'Finding assistant',
            'started' => 'In progress',
            'pending' => 'Draft',
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
                Text(
                  b.isPaymentPending ? 'Complete payment' : 'Active booking',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('📍 ${b.venueName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (!b.isPaymentPending && b.assistant != null) ...[
              const SizedBox(height: 10),
              AssistantIdBadge(assistant: b.assistant, compact: true),
              const SizedBox(height: 8),
              Text(
                '$assistantName • ★ ${rating.toStringAsFixed(1)} • ${b.category?.name ?? "Service"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ] else if (b.isPaymentPending) ...[
              const SizedBox(height: 10),
              Text(
                'Pay ₹${b.totalAmount.toStringAsFixed(0)} to finish this booking. New bookings unlock after payment.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'Finish this booking before starting another.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => navigateToResolveBlockingBooking(context, b),
                    icon: Icon(b.isPaymentPending ? Icons.payment : Icons.my_location, size: 18),
                    label: Text(b.isPaymentPending ? 'Pay now' : 'View booking'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (!b.isPaymentPending && b.assistant != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => callAssistant(assistantPhone),
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
