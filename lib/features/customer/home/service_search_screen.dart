import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dev/dev_data_store.dart';
import '../../../core/providers/providers.dart';
import '../../../features/booking/booking_block_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import 'quick_book_draft.dart';

class ServiceSearchScreen extends ConsumerStatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  ConsumerState<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends ConsumerState<ServiceSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<ServiceCategoryModel> _categories = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await ref.read(bookingRepositoryProvider).getCategories();
      if (mounted) setState(() { _categories = cats; _loading = false; });
    } catch (_) {
      if (mounted) {
        DevDataStore.instance.ensureSeeded();
        setState(() { _categories = DevDataStore.categories; _loading = false; });
      }
    }
  }

  List<ServiceCategoryModel> get _results {
    final q = _query.trim().toLowerCase();
    final items = _categories.isNotEmpty ? _categories : DevDataStore.categories;
    if (q.isEmpty) return items;
    return items.where((c) {
      final slug = c.slug.replaceAll('_', ' ');
      return c.name.toLowerCase().contains(q) || slug.contains(q);
    }).toList();
  }

  Future<void> _openService(ServiceCategoryModel c) async {
    final blocking = await ref.read(bookingRepositoryProvider).getCustomerBlockingBooking();
    if (!mounted) return;
    if (blocking != null) {
      navigateToResolveBlockingBooking(context, blocking);
      return;
    }
    context.push(
      '/customer/booking',
      extra: QuickBookDraft(categorySlug: c.slug),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) {
            if (results.isNotEmpty) _openService(results.first);
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search service — Bag carry, Queue help...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.75), fontWeight: FontWeight.w400),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : results.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = results[i];
                    final color = AppColors.categoryColor(c.slug);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _openService(c),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconFor(c.slug), color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('₹${c.baseRate.toInt()}/hour', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No service found for "$_query"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
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
