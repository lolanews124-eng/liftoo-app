import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/screen_safe_padding.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/booking_detail_sheet.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../booking/booking_flow.dart';
import '../booking/cancel_booking_dialog.dart';
import '../../../shared/widgets/booking_list_card.dart';

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
      if (mounted) {
        setState(() {
          _data[status] = list;
          _errors[status] = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data[status] = [];
          _errors[status] = NetworkErrors.userMessage(e);
        });
      }
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

  void _showBookingDetail(BookingModel b, String tabStatus) {
    String? primaryLabel;
    VoidCallback? primaryAction;
    String? secondaryLabel;
    VoidCallback? secondaryAction;

    if (b.isActive) {
      primaryLabel = 'Track live';
      primaryAction = () => context.push('/customer/booking/${b.id}');
      if (tabStatus == 'upcoming' && b.status != 'started') {
        secondaryLabel = 'Cancel booking';
        secondaryAction = () => _cancel(b);
      }
    } else if (b.status == 'completed') {
      if (!b.isPaid) {
        primaryLabel = 'Pay now';
        primaryAction = () => context.push('/customer/payment/${b.id}');
      } else if (!b.hasServiceReview) {
        primaryLabel = 'Rate service';
        primaryAction = () => openServiceReview(context, b.id);
      } else if (!b.hasAppReview) {
        primaryLabel = 'Rate app';
        primaryAction = () => openAppReview(context, b.id);
      }
    }

    showBookingDetailSheet(
      context,
      booking: b,
      isAssistantView: false,
      primaryActionLabel: primaryLabel,
      onPrimaryAction: primaryAction,
      secondaryActionLabel: secondaryLabel,
      onSecondaryAction: secondaryAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
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
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
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
            color: AppColors.primary,
            onRefresh: () => _load(status),
            child: ListView.builder(
              padding: shellScrollPadding(context, top: 12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final b = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookingListCard(
                    booking: b,
                    tabStatus: status,
                    onTap: () => _showBookingDetail(b, status),
                    onCancel: status == 'upcoming' && b.isActive && b.status != 'started'
                        ? () => _cancel(b)
                        : null,
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
