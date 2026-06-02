import '../../../shared/models/user_model.dart';
import '../../../core/dev/dev_data_store.dart';

/// Offline demo login when API is not running (debug only).
class DevAuthMock {
  static const enabled = bool.fromEnvironment('DEV_MOCK_AUTH', defaultValue: false);

  static bool get isEnabled => enabled;

  static bool isValidOtp(String otp) => otp == '123456';

  static final Set<String> _verifiedEmails = {};

  static String _key(String email) => email.trim().toLowerCase().replaceAll('@', '-at-');

  static void markEmailVerified(String email) => _verifiedEmails.add(_key(email));

  static bool isEmailVerified(String email) => _verifiedEmails.contains(_key(email));

  static UserModel _buildUser({
    required String id,
    required String email,
    String? name,
    String? avatarUrl,
    bool? profileComplete,
  }) {
    final stored = DevDataStore.instance.getUserProfile(id);
    final complete = profileComplete ??
        stored?['profileComplete'] == true ||
        (name?.trim().isNotEmpty == true &&
            (stored?['phone'] as String?)?.length == 10);

    return UserModel(
      id: id,
      email: email,
      phone: stored?['phone'] as String?,
      name: stored?['name'] as String? ?? name,
      avatarUrl: stored?['avatarUrl'] as String? ?? avatarUrl,
      roles: const ['customer', 'assistant'],
      activeRole: null,
      referralCode: 'LIFDEV',
      walletBalance: DevDataStore.instance.walletBalance,
      isOnline: false,
      emailVerified: true,
      profileComplete: complete,
      assistantProfile: const AssistantProfileModel(
        rating: 4.9,
        totalJobs: 48,
        profileCompletion: 85,
      ),
    );
  }

  static ({UserModel user, bool isNew}) verify(String email) {
    markEmailVerified(email);
    final id = 'dev-user-${_key(email)}';
    final user = _buildUser(
      id: id,
      email: email.trim().toLowerCase(),
      profileComplete: DevDataStore.instance.isUserProfileComplete(id),
    );
    return (user: user, isNew: !user.profileComplete);
  }

  static UserModel userFromToken(String token, {String? role}) {
    final key = token.replaceFirst('dev-mock-', '');
    final email = key.replaceAll('-at-', '@');
    return _buildUser(
      id: 'dev-user-$key',
      email: email,
      profileComplete: DevDataStore.instance.isUserProfileComplete('dev-user-$key'),
    ).copyWith(activeRole: role);
  }
}
