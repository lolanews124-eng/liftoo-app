import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';

void navigateAfterAuth(BuildContext context, UserModel user) {
  if (!user.profileComplete) {
    context.go('/auth/setup-profile');
  } else if (user.activeRole == null) {
    context.go('/role-selection');
  } else if (user.activeRole == 'assistant') {
    context.go('/assistant');
  } else {
    context.go('/customer');
  }
}
