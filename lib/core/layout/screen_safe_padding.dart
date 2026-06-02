import 'package:flutter/material.dart';

/// Bottom inset for system gesture area only.
EdgeInsets screenBottomInset(BuildContext context, {double extra = 0}) {
  final padding = MediaQuery.paddingOf(context);
  return EdgeInsets.only(bottom: padding.bottom + extra);
}

/// Customer shell: [BottomAppBar] (64) + center-docked FAB clearance + safe area.
/// Use as ListView / scroll view bottom padding so last items are not hidden.
double shellScrollBottomPadding(BuildContext context, {double extra = 16}) {
  const navBarHeight = 64.0;
  const fabNotchClearance = 52.0;
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  return navBarHeight + fabNotchClearance + safeBottom + extra;
}

EdgeInsets shellScrollPadding(BuildContext context, {
  double horizontal = 20,
  double top = 0,
  double extraBottom = 16,
}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    shellScrollBottomPadding(context, extra: extraBottom),
  );
}

/// Wrap scrollable screen footers (buttons) to avoid system gesture overlap.
class SafeBottomBar extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SafeBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.copyWith(
        bottom: padding.bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: child,
    );
  }
}
