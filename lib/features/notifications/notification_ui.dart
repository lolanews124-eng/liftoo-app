import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

IconData notificationIcon(String? type) {
  switch (type) {
    case 'admin_broadcast':
      return Icons.campaign_outlined;
    case 'new_booking':
    case 'booking_update':
      return Icons.event_note_outlined;
    case 'assistant_assigned':
    case 'assistant_arriving':
    case 'service_started':
      return Icons.directions_walk_outlined;
    case 'payment':
    case 'payment_received':
      return Icons.account_balance_wallet_outlined;
    case 'referral':
      return Icons.card_giftcard_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color notificationIconColor(String? type) {
  switch (type) {
    case 'admin_broadcast':
      return AppColors.primary;
    case 'payment':
    case 'payment_received':
      return AppColors.success;
    case 'referral':
      return AppColors.purple;
    default:
      return AppColors.navy;
  }
}

String formatNotificationTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${local.day}/${local.month}/${local.year}';
}

String formatNotificationDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min $ampm';
}

/// Optional deep-link action label from notification title/type.
String? notificationActionLabel(Map<String, dynamic> n) {
  final title = (n['title'] as String? ?? '').toLowerCase();
  final type = n['type'] as String? ?? '';
  if (title.contains('booking') ||
      title.contains('assistant') ||
      title.contains('way') ||
      type.contains('booking') ||
      type.contains('assistant') ||
      type.contains('service')) {
    return 'View bookings';
  }
  if (title.contains('refer') || type == 'referral') return 'Open referral';
  if (title.contains('payment') || type.contains('payment')) return 'Open wallet';
  return null;
}
