import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'keyboard_aware_scroll.dart';

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
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              autofocus: true,
              scrollPadding: keyboardScrollPadding(context),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                widget.onChanged?.call(v);
                setState(() {});
                if (v.length == widget.length) widget.onCompleted(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final char = i < _controller.text.length ? _controller.text[i] : '';
              final filled = char.isNotEmpty;
              final active = i == _controller.text.length;
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
        ],
      ),
    );
  }
}
