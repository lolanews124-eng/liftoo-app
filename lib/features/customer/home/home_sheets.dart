import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/service_location_model.dart';
import 'booking_duration_options.dart';

export 'booking_duration_options.dart';
export 'location_picker_sheet.dart' show showLocationPicker;

void showSavedAddressesSheet(
  BuildContext context, {
  required List<ServiceLocationModel> savedLocations,
  VoidCallback? onManage,
  void Function(ServiceLocationModel)? onSelect,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Saved addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          if (savedLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No saved addresses yet. Add one from Profile → Saved addresses.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...savedLocations.map(
              (loc) => ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                title: Text(loc.name),
                subtitle: Text(loc.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect?.call(loc);
                },
              ),
            ),
          if (onManage != null)
            ListTile(
              leading: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary),
              title: const Text('Manage saved addresses'),
              onTap: () {
                Navigator.pop(ctx);
                onManage();
              },
            ),
        ],
      ),
    ),
  );
}

Future<int?> showDurationPicker(BuildContext context, int currentMin) {
  return showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Select duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          ...BookingDurationOptions.options.map(
            (o) => ListTile(
              title: Text(o.label),
              trailing: o.minutes == currentMin ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(ctx, o.minutes),
            ),
          ),
        ],
      ),
    ),
  );
}

void showSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _supportTile(
              ctx,
              Icons.email_outlined,
              'Email support',
              AppConfig.supportEmail,
              () => _launchEmail(AppConfig.supportEmail),
            ),
            _supportTile(
              ctx,
              Icons.delete_outline_rounded,
              'Delete account',
              AppConfig.accountDeletionEmail,
              () => _launchEmail(AppConfig.accountDeletionEmail),
            ),
          ],
        ),
      ),
    ),
  );
}

void showHelpSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scroll) => SafeArea(
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Help Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            _FaqTile(
              q: 'What is Liftoo?',
              a: 'Liftoo helps you book trained shopping assistants for malls, markets, and exhibitions.',
            ),
            _FaqTile(
              q: 'How do I cancel a booking?',
              a: 'Open the active booking from My Bookings and tap Cancel.',
            ),
            _FaqTile(
              q: 'How does payment work?',
              a: 'You can pay using wallet, UPI, or cash.',
            ),
            _FaqTile(
              q: 'How does Refer & Earn work?',
              a: 'Share your referral code. When a friend completes their first paid booking, you earn the referral reward shown in Refer & Earn (set by Liftoo).',
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _supportTile(BuildContext ctx, IconData icon, String title, String subtitle, VoidCallback onTap) {
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: AppColors.primaryLight,
      child: Icon(icon, color: AppColors.primary, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

Future<void> callAssistant(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'\D'), '');
  if (normalized.length < 10) return;
  final uri = Uri.parse('tel:$normalized');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> _launchEmail(String email) async {
  final uri = Uri.parse('mailto:$email');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;

  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(widget.q, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Icon(_open ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
                if (_open) ...[
                  const SizedBox(height: 8),
                  Text(widget.a, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
