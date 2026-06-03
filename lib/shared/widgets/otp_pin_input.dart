import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'keyboard_aware_scroll.dart';

/// Six-digit OTP boxes with a real, tappable [TextField] overlay (keyboard opens on Android/iOS).
class OtpPinInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpPinInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpPinInput> createState() => _OtpPinInputState();
}

class _OtpPinInputState extends State<OtpPinInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _focusField() {
    if (!_focus.hasFocus) {
      _focus.requestFocus();
    }
    // Ensures keyboard opens even when focus was already on the field.
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusField,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (i) {
                final char = i < text.length ? text[i] : '';
                final filled = char.isNotEmpty;
                final active = i == text.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : filled
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                      width: active ? 2 : 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filled ? char : '•',
                    style: TextStyle(
                      fontSize: filled ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: filled ? AppColors.charcoal : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: widget.length,
                autofocus: true,
                showCursor: false,
                enableSuggestions: false,
                autocorrect: false,
                enableInteractiveSelection: false,
                scrollPadding: keyboardScrollPadding(context),
                style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTap: _focusField,
                onChanged: (v) {
                  widget.onChanged?.call(v);
                  setState(() {});
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
