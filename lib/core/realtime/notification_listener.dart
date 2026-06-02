import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'in_app_notification_banner.dart';

/// Live in-app notifications via socket `notification:new`.
class NotificationRealtimeListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationRealtimeListener({super.key, required this.child});

  @override
  ConsumerState<NotificationRealtimeListener> createState() => _NotificationRealtimeListenerState();
}

class _NotificationRealtimeListenerState extends ConsumerState<NotificationRealtimeListener> {
  void _onNotification(dynamic data) {
    if (data is! Map) return;
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    ref.read(unreadNotificationCountProvider.notifier).state++;
    showInAppNotification(ref, title: title, body: body);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).on('notification:new', _onNotification);
      _refreshUnread();
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('notification:new', _onNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (next.user != null && prev?.user?.id != next.user?.id) {
        _refreshUnread();
      }
    });
    return widget.child;
  }

  Future<void> _refreshUnread() async {
    try {
      final list = await ref.read(walletRepositoryProvider).getNotifications();
      final unread = list.where((n) => (n as Map)['readAt'] == null).length;
      ref.read(unreadNotificationCountProvider.notifier).state = unread;
    } catch (_) {}
  }
}

final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);
