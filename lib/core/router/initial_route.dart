import '../../features/auth/providers/auth_provider.dart';

/// First screen after the one-time native splash (no /splash route).
String resolveInitialLocation(AuthState auth) {
  final user = auth.user;
  if (user == null) return '/auth/login';
  if (!user.profileComplete) return '/auth/setup-profile';
  if (user.activeRole == null) return '/role-selection';
  return user.activeRole == 'assistant' ? '/assistant' : '/customer';
}
