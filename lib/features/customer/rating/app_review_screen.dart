import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';

class AppReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const AppReviewScreen({super.key, required this.bookingId});

  @override
  ConsumerState<AppReviewScreen> createState() => _AppReviewScreenState();
}

class _AppReviewScreenState extends ConsumerState<AppReviewScreen> {
  int _stars = 5;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewsRepositoryProvider).submitAppReview(
            _stars,
            bookingId: widget.bookingId,
            comment: _commentController.text.isEmpty ? null : _commentController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        context.go('/customer');
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
        title: const Text('Rate Liftoo'),
        backgroundColor: AppColors.surface,
      ),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Enjoying Liftoo?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Your app rating helps us improve and serve you better.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 46,
                  onPressed: () => setState(() => _stars = i + 1),
                  icon: Icon(i < _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              scrollPadding: keyboardScrollPadding(context),
              decoration: InputDecoration(
                hintText: 'Tell us what you love or what we can improve (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(label: 'Submit app review', isLoading: _loading, onPressed: _submit),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading ? null : () => context.go('/customer'),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
