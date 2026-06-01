import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _load() async {
    final t = await ref.read(supportRepositoryProvider).getTickets();
    if (mounted) setState(() => _tickets = t);
  }

  Future<void> _submit() async {
    if (_subject.text.trim().length < 3 || _message.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill subject and message')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted. We will reply soon.')));
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Help & Support')),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text('New ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            scrollPadding: keyboardScrollPadding(context),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLines: 4,
            scrollPadding: keyboardScrollPadding(context),
            decoration: const InputDecoration(labelText: 'Describe your issue'),
          ),          const SizedBox(height: 16),
          GradientButton(label: 'Submit ticket', isLoading: _loading, onPressed: _submit),
          const SizedBox(height: 28),
          const Text('Your tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_tickets.isEmpty)
            const LiftooCard(child: Text('No tickets yet', style: TextStyle(color: AppColors.textSecondary)))
          else
            ..._tickets.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LiftooCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['subject'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(t['status'] as String? ?? 'open', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                        if (t['adminReply'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Reply: ${t['adminReply']}', style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
