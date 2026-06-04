import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/realtime/notification_listener.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/network_error_state.dart';
import 'notification_detail_sheet.dart';
import 'notification_ui.dart';

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
        title: const Text('Clear all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all', style: TextStyle(color: AppColors.error)),
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

  Future<void> _openNotification(Map<String, dynamic> n) async {
    final id = n['id'] as String?;
    if (id != null && n['readAt'] == null) {
      try {
        await ref.read(walletRepositoryProvider).markNotificationRead(id);
        if (mounted) {
          setState(() {
            final i = _notifications.indexWhere((x) => (x as Map)['id'] == id);
            if (i >= 0) {
              _notifications[i] = {
                ...(_notifications[i] as Map<String, dynamic>),
                'readAt': DateTime.now().toIso8601String(),
              };
            }
          });
          _syncUnreadBadge();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await showNotificationDetailSheet(context, notification: n);
  }

  bool get _hasUnread => _notifications.any((n) => (n as Map)['readAt'] == null);

  @override
  Widget build(BuildContext context) {
    final hasItems = _notifications.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (hasItems && _hasUnread)
            TextButton(
              onPressed: _actionLoading ? null : _markAllRead,
              child: const Text('Mark read', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (hasItems)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
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
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, i) {
                          final n = _notifications[i] as Map<String, dynamic>;
                          final unread = n['readAt'] == null;
                          final id = n['id'] as String? ?? '$i';
                          final type = n['type'] as String?;
                          final title = n['title'] as String? ?? '';
                          final body = n['body'] as String? ?? '';
                          final time = formatNotificationTime(n['createdAt'] as String?);

                          return Dismissible(
                            key: ValueKey(id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.error.withValues(alpha: 0.08),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_outline, color: AppColors.error),
                            ),
                            onDismissed: (_) => _deleteOne(id),
                            child: Material(
                              color: unread ? AppColors.primaryLight.withValues(alpha: 0.35) : Colors.white,
                              child: InkWell(
                                onTap: () => _openNotification(n),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: notificationIconColor(type).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          notificationIcon(type),
                                          color: notificationIconColor(type),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (time.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    time,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: unread ? AppColors.primary : AppColors.textSecondary,
                                                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (body.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.35,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (unread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 9,
                                          height: 9,
                                          margin: const EdgeInsets.only(top: 6),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
