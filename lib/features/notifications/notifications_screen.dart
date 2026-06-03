import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/realtime/notification_listener.dart';
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
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncUnreadBadge() {
    final unread = _notifications.where((n) => (n as Map)['readAt'] == null).length;
    ref.read(unreadNotificationCountProvider.notifier).state = unread;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(walletRepositoryProvider).getNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
        _syncUnreadBadge();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = NetworkErrors.userMessage(e);
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_actionLoading || _notifications.isEmpty) return;
    setState(() => _actionLoading = true);
    try {
      await ref.read(walletRepositoryProvider).markAllNotificationsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrors.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _deleteAll() async {
    if (_actionLoading || _notifications.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(walletRepositoryProvider).deleteAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications cleared')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrors.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _deleteOne(String id) async {
    try {
      await ref.read(walletRepositoryProvider).deleteNotification(id);
      if (mounted) {
        setState(() => _notifications.removeWhere((n) => (n as Map)['id'] == id));
        _syncUnreadBadge();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrors.userMessage(e))),
        );
      }
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    final id = n['id'] as String?;
    if (id != null && n['readAt'] == null) {
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

  bool get _hasUnread => _notifications.any((n) => (n as Map)['readAt'] == null);

  @override
  Widget build(BuildContext context) {
    final hasItems = _notifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasItems && _hasUnread)
            TextButton(
              onPressed: _actionLoading ? null : _markAllRead,
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (hasItems)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete all',
              onPressed: _actionLoading ? null : _deleteAll,
            ),
        ],
      ),
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
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i] as Map<String, dynamic>;
                          final unread = n['readAt'] == null;
                          final id = n['id'] as String? ?? '$i';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Dismissible(
                              key: ValueKey(id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline, color: AppColors.error),
                              ),
                              onDismissed: (_) => _deleteOne(id),
                              child: LiftooCard(
                                onTap: () => _open(n),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: unread ? AppColors.primary : Colors.transparent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['title'] ?? '',
                                            style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                                          ),
                                          Text(
                                            n['body'] ?? '',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                                      onPressed: () => _deleteOne(id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
