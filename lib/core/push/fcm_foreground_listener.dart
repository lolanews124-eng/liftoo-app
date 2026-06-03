import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../realtime/in_app_notification_banner.dart';

/// Shows admin / system pushes when the app is open (background still uses system tray).
class FcmForegroundListener extends ConsumerStatefulWidget {
  final Widget child;

  const FcmForegroundListener({super.key, required this.child});

  @override
  ConsumerState<FcmForegroundListener> createState() => _FcmForegroundListenerState();
}

class _FcmForegroundListenerState extends ConsumerState<FcmForegroundListener> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Liftoo';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (!mounted) return;
      ref.read(unreadNotificationCountProvider.notifier).state++;
      showInAppNotification(ref, title: title, body: body);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
