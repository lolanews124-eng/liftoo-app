import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/review_models.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/liftoo_card.dart';
import '../booking/booking_flow_cache.dart';
import '../booking/booking_flow.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 5;
  final _commentController = TextEditingController();
  bool _loading = false;
  BookingModel? _booking;
  AssistantStatsModel? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var b = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
      if (!b.isPaid) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        b = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
      }
      AssistantStatsModel? stats;
      final assistantId = b.assistant?['id'] as String?;
      if (assistantId != null) {
        try {
          stats = await ref.read(reviewsRepositoryProvider).getAssistantStats(assistantId);
        } catch (_) {
          stats = AssistantStatsModel.fromAssistantMap(b.assistant!);
        }
      } else if (b.assistant != null) {
        stats = AssistantStatsModel.fromAssistantMap(b.assistant!);
      }
      if (!mounted) return;
      setState(() {
        _booking = b;
        _stats = stats;
      });
      if (!b.isPaid && !BookingFlowCache.instance.wasJustPaid(widget.bookingId)) {
        context.go('/customer/payment/${b.id}');
        return;
      }
      BookingFlowCache.instance.clearPaid(widget.bookingId);
      if (b.hasServiceReview && !b.hasAppReview) {
        openAppReview(context, b.id);
      } else if (b.hasAppReview) {
        context.go('/customer');
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(reviewsRepositoryProvider).submitServiceReview(
            widget.bookingId,
            _stars,
            comment: _commentController.text.isEmpty ? null : _commentController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service review submitted!')));
        if (result.nextStep == 'rate_app') {
          openAppReview(context, widget.bookingId);
        } else {
          context.go('/customer');
        }
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistantName = _booking?.assistant?['name'] ?? 'your assistant';
    final stats = _stats;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Rate your assistant'),
        backgroundColor: AppColors.surface,
      ),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (stats != null) ...[
              LiftooCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(stats.name[0], style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stats.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${stats.rating.toStringAsFixed(1)} rating', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${stats.totalJobs} jobs', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (stats.reviewCount > 0)
                            Text('${stats.reviewCount} reviews', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('How was $assistantName?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Your feedback helps other shoppers choose trusted assistants.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 44,
                  onPressed: () => setState(() => _stars = i + 1),
                  icon: Icon(i < _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              scrollPadding: keyboardScrollPadding(context),
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(label: 'Submit service review', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
