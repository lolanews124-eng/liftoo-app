import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/screen_safe_padding.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/booking_detail_sheet.dart';
import '../../../shared/widgets/booking_list_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class AssistantJobsScreen extends ConsumerStatefulWidget {
  const AssistantJobsScreen({super.key});

  @override
  ConsumerState<AssistantJobsScreen> createState() => _AssistantJobsScreenState();
}

class _AssistantJobsScreenState extends ConsumerState<AssistantJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _filters = ['active', 'completed', 'cancelled'];
  final Map<String, List<BookingModel>> _data = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load(_filters[_tabs.index]);
    });
    for (final f in _filters) {
      _load(f);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String? _apiStatus(String filter) => switch (filter) {
        'active' => 'upcoming',
        'completed' => 'completed',
        'cancelled' => 'cancelled',
        _ => null,
      };

  String _tabStatus(String filter) => switch (filter) {
        'active' => 'upcoming',
        _ => filter,
      };

  Future<void> _load(String filter) async {
    try {
      final list = await ref.read(bookingRepositoryProvider).getBookings(
            status: _apiStatus(filter),
            asRole: 'assistant',
          );
      if (!mounted) return;
      setState(() {
        _data[filter] = list;
        _errors[filter] = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data[filter] = [];
        _errors[filter] = NetworkErrors.userMessage(e);
      });
    }
  }

  void _openDetail(BookingModel b) {
    String? primaryLabel;
    VoidCallback? primaryAction;

    if (b.isActive || b.isPaymentPending) {
      primaryLabel = b.isPaymentPending ? 'Collect payment' : 'Open active job';
      primaryAction = () => context.push('/assistant/active/${b.id}');
    }

    showBookingDetailSheet(
      context,
      booking: b,
      isAssistantView: true,
      onPrimaryAction: primaryAction,
      primaryActionLabel: primaryLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'New requests',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () => context.push('/assistant/nearby-requests'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Complete'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _filters.map((filter) {
          final list = _data[filter];
          if (list == null) return const ListScreenSkeleton();
          if (_errors[filter] != null) {
            return NetworkErrorState(
              message: _errors[filter],
              onRetry: () => _load(filter),
            );
          }
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.work_outline,
              title: 'No ${filter == 'active' ? 'active' : filter} jobs',
              subtitle: filter == 'active'
                  ? 'Accepted jobs will appear here'
                  : 'Your job history will show here',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(filter),
            child: ListView.builder(
              padding: shellScrollPadding(context, top: 12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final b = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookingListCard(
                    booking: b,
                    tabStatus: _tabStatus(filter),
                    isAssistantView: true,
                    onTap: () => _openDetail(b),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
