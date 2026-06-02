import 'package:flutter/material.dart';

/// Root navigator for overlays (dialogs) above [GoRouter] shell routes.
final rootNavigatorKey = GlobalKey<NavigatorState>();

BuildContext? get rootNavigatorContext => rootNavigatorKey.currentContext;
