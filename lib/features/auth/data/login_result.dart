import '../../../shared/models/user_model.dart';

class LoginResult {
  final bool requiresOtp;
  final UserModel? user;
  final bool isNewUser;

  const LoginResult({
    required this.requiresOtp,
    this.user,
    this.isNewUser = false,
  });
}
