import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class InAppNotification {
  final String id;
  final String title;
  final String body;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
  });
}

final inAppNotificationProvider = StateProvider<InAppNotification?>((ref) => null);

Timer? _inAppNotificationDismissTimer;

void showInAppNotification(
  WidgetRef ref, {
  required String title,
  required String body,
}) {
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  ref.read(inAppNotificationProvider.notifier).state = InAppNotification(
    id: id,
    title: title,
    body: body,
  );
  _inAppNotificationDismissTimer?.cancel();
  _inAppNotificationDismissTimer = Timer(const Duration(seconds: 5), () {
    final current = ref.read(inAppNotificationProvider);
    if (current?.id == id) {
      ref.read(inAppNotificationProvider.notifier).state = null;
    }
  });
}

void dismissInAppNotification(WidgetRef ref) {
  _inAppNotificationDismissTimer?.cancel();
  ref.read(inAppNotificationProvider.notifier).state = null;
}

/// Top-of-screen notification banner (below status bar / no-internet strip).
class InAppNotificationBanner extends ConsumerWidget {
  const InAppNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(inAppNotificationProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: notification == null
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : Material(
              key: ValueKey(notification.id),
              color: AppColors.navy,
              elevation: 6,
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () {
                    dismissInAppNotification(ref);
                    context.push('/notifications');
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              if (notification.body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  notification.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            dismissInAppNotification(ref);
                            context.push('/notifications');
                          },
                          child: const Text('View', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close, size: 20, color: Colors.white.withValues(alpha: 0.85)),
                          onPressed: () => dismissInAppNotification(ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
