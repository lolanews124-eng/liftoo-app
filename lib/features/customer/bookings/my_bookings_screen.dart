import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../booking/booking_flow.dart';
import '../booking/cancel_booking_dialog.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _statuses = ['upcoming', 'completed', 'cancelled'];
  final Map<String, List<BookingModel>> _data = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load(_statuses[_tabs.index]);
    });
    _load('upcoming');
    _load('completed');
    _load('cancelled');
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load(String status) async {
    try {
      final list = await ref.read(bookingRepositoryProvider).getBookings(status: status);
      if (mounted) setState(() {
        _data[status] = list;
        _errors[status] = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _data[status] = [];
        _errors[status] = NetworkErrors.userMessage(e);
      });
    }
  }

  Future<void> _cancel(BookingModel b) async {
    final result = await showCancelBookingDialog(context, venueName: b.venueName);
    if (result == null) return;
    await ref.read(bookingRepositoryProvider).cancelBooking(
          b.id,
          reason: result.reason,
          note: result.note,
        );
    _load('upcoming');
    _load('cancelled');
  }

  void _openBooking(BookingModel b) {
    navigateBookingNextStep(context, b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _statuses.map((status) {
          final list = _data[status];
          if (list == null) {
            return const ListScreenSkeleton();
          }
          if (_errors[status] != null) {
            return NetworkErrorState(
              message: _errors[status],
              offline: _errors[status] == NetworkErrors.noInternet,
              onRetry: () => _load(status),
            );
          }
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No $status bookings',
              subtitle: 'Book an assistant from home',
            );
          }
          return RefreshIndicator(
            onRefresh: () => _load(status),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final b = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LiftooCard(
                    onTap: () => _openBooking(b),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(b.category?.name ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                              child: Text(b.status, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(b.venueName, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM d, h:mm a').format(b.scheduledAt)),
                            Text('₹${b.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (b.assistant != null) ...[
                          const SizedBox(height: 8),
                          Text('Assistant: ${b.assistant!['name']}', style: const TextStyle(fontSize: 13)),
                        ],
                        if (status == 'upcoming' && b.isActive && b.status != 'started') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _cancel(b),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                            ),
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
