import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';

class CancelBookingResult {
  final String reason;
  final String? note;

  const CancelBookingResult({required this.reason, this.note});
}

const _cancelReasons = [
  'Changed my plans',
  'Booked by mistake',
  'Assistant is taking too long',
  'Found another option',
  'Wrong location or time',
  'Other',
];

/// Polished cancellation sheet with mandatory reason.
Future<CancelBookingResult?> showCancelBookingDialog(
  BuildContext context, {
  String? venueName,
}) {
  return showDialog<CancelBookingResult>(
    context: context,
    barrierColor: Colors.black45,
    builder: (ctx) => _CancelBookingDialog(venueName: venueName),
  );
}

class _CancelBookingDialog extends StatefulWidget {
  final String? venueName;

  const _CancelBookingDialog({this.venueName});

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  String? _selectedReason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other') return _noteController.text.trim().length >= 3;
    return true;
  }

  void _submit() {
    if (!_canSubmit || _selectedReason == null) return;
    Navigator.pop(
      context,
      CancelBookingResult(
        reason: _selectedReason!,
        note: _selectedReason == 'Other' ? _noteController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venueName;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
        child: Padding(
          padding: keyboardInsetPadding(context, base: const EdgeInsets.fromLTRB(24, 28, 24, 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_busy_rounded, size: 34, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Cancel booking?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                venue != null
                    ? 'Tell us why you want to cancel your booking at $venue.'
                    : 'Please select a reason so we can improve your experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _cancelReasons.map((reason) {
                      final selected = _selectedReason == reason;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedReason = reason),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppColors.primary.withValues(alpha: 0.45) : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 20,
                                  color: selected ? AppColors.primary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                      color: AppColors.charcoal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selectedReason == 'Other') ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 2,
                  maxLength: 120,
                  scrollPadding: keyboardScrollPadding(context),
                  decoration: InputDecoration(
                    hintText: 'Briefly describe your reason',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Keep booking', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        disabledBackgroundColor: AppColors.error.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel booking', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
