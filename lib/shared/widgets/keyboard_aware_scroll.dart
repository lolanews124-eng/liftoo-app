import 'package:flutter/material.dart';

/// Scrollable body that keeps focused fields visible when the software keyboard opens.
class KeyboardAwareScroll extends StatelessWidget {
  const KeyboardAwareScroll({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.extraBottom = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double extraBottom;

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding.add(EdgeInsets.only(bottom: keyboardBottom + extraBottom)),
      child: child,
    );
  }
}

/// Bottom inset for dialogs and bottom sheets when the keyboard is open.
EdgeInsets keyboardInsetPadding(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
  double extra = 16,
}) {
  final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
  return base.copyWith(bottom: base.bottom + keyboardBottom + extra);
}

/// Recommended [TextField.scrollPadding] so focused fields scroll above the keyboard.
EdgeInsets keyboardScrollPadding(BuildContext context, {double extra = 120}) {
  return EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + extra);
}
