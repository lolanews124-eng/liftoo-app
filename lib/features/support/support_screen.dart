import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';

class SupportScreen extends ConsumerStatefulWidget {
  final String? bookingId;

  const SupportScreen({super.key, this.bookingId});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final t = await ref.read(supportRepositoryProvider).getTickets();
    if (mounted) setState(() => _tickets = t);
  }

  Future<void> _submit() async {
    if (_subject.text.trim().length < 3 || _message.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill subject and message')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(supportRepositoryProvider).createTicket(
            subject: _subject.text.trim(),
            message: _message.text.trim(),
            bookingId: widget.bookingId,
          );
      _subject.clear();
      _message.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted. We will reply soon.')),
        );
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContactStrip(
              onCall: () => _launchTel('18001234567'),
              onEmail: () => _launchEmail('help@liftoo.in'),
              onWhatsApp: () => _launchWhatsApp('919876543210'),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('FAQs'),
            const SizedBox(height: 10),
            const _FaqTile(
              q: 'What is Liftoo?',
              a: 'Liftoo helps you book trained shopping assistants for malls, markets, and exhibitions.',
            ),
            const _FaqTile(
              q: 'How do I cancel a booking?',
              a: 'Open the booking from the Bookings tab and tap Cancel.',
            ),
            const _FaqTile(
              q: 'How does payment work?',
              a: 'You can pay using wallet, UPI, or cash.',
            ),
            const _FaqTile(
              q: 'How does Refer & Earn work?',
              a: 'Share your referral code. When a friend completes their first paid booking, you earn the reward shown in Refer & Earn.',
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Raise a ticket'),
            const SizedBox(height: 6),
            const Text(
              'Describe your issue and our team will respond.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _subject,
                    scrollPadding: keyboardScrollPadding(context),
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _message,
                    maxLines: 4,
                    scrollPadding: keyboardScrollPadding(context),
                    decoration: const InputDecoration(
                      labelText: 'Describe your issue',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(label: 'Submit ticket', isLoading: _loading, onPressed: _submit),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Your tickets'),
            const SizedBox(height: 12),
            if (_tickets.isEmpty)
              const LiftooCard(
                child: Text('No tickets yet', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ..._tickets.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['subject'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t['status'] as String? ?? 'open',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (t['adminReply'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Reply: ${t['adminReply']}', style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
    );
  }
}

class _ContactStrip extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;

  const _ContactStrip({
    required this.onCall,
    required this.onEmail,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactChip(icon: Icons.phone_rounded, label: 'Call', onTap: onCall),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ContactChip(icon: Icons.email_outlined, label: 'Email', onTap: onEmail),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ContactChip(icon: Icons.chat_rounded, label: 'WhatsApp', onTap: onWhatsApp),
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.q,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ),
                    Icon(
                      _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (_open) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.a,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchTel(String phone) async {
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> _launchEmail(String email) async {
  final uri = Uri.parse('mailto:$email');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> _launchWhatsApp(String phone) async {
  final uri = Uri.parse('https://wa.me/$phone');
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
