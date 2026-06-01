import 'package:flutter/material.dart';
import 'network_errors.dart';

void showAppErrorSnackBar(BuildContext context, Object error) {
  if (!context.mounted) return;
  final msg = NetworkErrors.userMessage(error);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
