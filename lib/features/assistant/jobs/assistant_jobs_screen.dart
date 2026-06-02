import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/booking_detail_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liftoo_card.dart';
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
    showBookingDetailSheet(
      context,
      booking: b,
      isAssistantView: true,
      onPrimaryAction: b.isActive ? () => context.push('/assistant/active/${b.id}') : null,
      primaryActionLabel: b.isActive ? 'Open active job' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            tooltip: 'New requests',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () => context.push('/assistant/nearby-requests'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Complete'),
            Tab(text: 'Cancelled'),
          ],
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
            onRefresh: () => _load(filter),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final b = list[i];
                final statusColor = bookingStatusColor(b.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LiftooCard(
                    onTap: () => _openDetail(b),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.category?.name ?? 'Service',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                formatBookingStatusLabel(b.status),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b.venueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(b.scheduledAt),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              '₹${b.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                            ),
                          ],
                        ),
                        if (b.customer != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Customer: ${b.customer!['name']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
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
