import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../../../shared/widgets/network_error_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
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
      final list = await ref.read(walletRepositoryProvider).getNotifications();
      if (mounted) setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = NetworkErrors.userMessage(e);
      });
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    final id = n['id'] as String?;
    if (id != null) {
      await ref.read(walletRepositoryProvider).markNotificationRead(id);
    }
    if (!mounted) return;
    final title = (n['title'] as String? ?? '').toLowerCase();
    if (title.contains('booking') || title.contains('assistant') || title.contains('way')) {
      context.go('/customer/bookings');
    } else if (title.contains('refer')) {
      context.push('/referral');
    } else if (title.contains('payment')) {
      context.go('/customer/wallet');
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? NetworkErrorState(
                  message: _error,
                  offline: _error == NetworkErrors.noInternet,
                  onRetry: _load,
                )
              : _notifications.isEmpty
              ? const EmptyState(icon: Icons.notifications_none, title: 'No notifications')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i] as Map<String, dynamic>;
                      final unread = n['readAt'] == null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LiftooCard(
                          onTap: () => _open(n),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: unread ? AppColors.primary : Colors.transparent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] ?? '', style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                                    Text(n['body'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
