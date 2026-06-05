import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_datetime.dart';

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
  final dt = parseAppTime(iso);
  if (dt == null) return '';
  final now = appNow();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String formatNotificationDateTime(String? iso) {
  return formatAppDateTimeIso(iso);
}

String? notificationActionLabel(Map<String, dynamic> notification) {
  final type = notification['type'] as String?;
  final title = (notification['title'] as String? ?? '').toLowerCase();

  switch (type) {
    case 'new_booking':
    case 'booking_update':
    case 'assistant_assigned':
    case 'assistant_arriving':
    case 'service_started':
    case 'booking_cancelled':
      return 'View bookings';
    case 'payment':
    case 'payment_received':
    case 'payment_completed':
    case 'earnings_credited':
      return 'Wallet';
    case 'referral':
      return 'Refer & earn';
    default:
      if (title.contains('booking') || title.contains('assistant') || title.contains('way')) {
        return 'View bookings';
      }
      if (title.contains('refer')) return 'Refer & earn';
      if (title.contains('payment')) return 'Wallet';
      return null;
  }
}
