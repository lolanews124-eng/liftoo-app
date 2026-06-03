import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/network/network_errors.dart';
import '../../assistant/shared/assistant_availability_tracker.dart';
import '../../../core/push/push_notification_service.dart';
import '../data/login_result.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AuthState(user: user, isLoading: false);
      if (user != null) {
        await PushNotificationService.instance.syncAfterLogin(ref);
      }
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<LoginResult> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(authRepositoryProvider).loginWithEmail(email, password);
      if (!result.requiresOtp && result.user != null) {
        state = AuthState(user: result.user, isLoading: false);
        await PushNotificationService.instance.syncAfterLogin(ref);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: NetworkErrors.userMessage(e));
      rethrow;
    }
  }

  Future<void> resendEmailOtp(String email, String password) async {
    await ref.read(authRepositoryProvider).resendEmailOtp(email, password);
  }

  Future<({UserModel user, bool isNew})> verifyEmailOtp(
    String email,
    String otp, {
    String? referralCode,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyEmailOtp(
            email,
            otp,
            referralCode: referralCode,
          );
      state = AuthState(user: result.user, isLoading: false);
      await PushNotificationService.instance.syncAfterLogin(ref);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: NetworkErrors.userMessage(e));
      rethrow;
    }
  }

  Future<void> setRole(AppRole role) async {
    final user = await ref.read(authRepositoryProvider).setRole(role);
    state = AuthState(user: user, isLoading: false);
  }

  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    state = AuthState(user: user, isLoading: false);
  }

  Future<UserModel> completeProfile({
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = await ref.read(authRepositoryProvider).completeProfile(
          name: name,
          phone: phone,
          avatarUrl: avatarUrl,
        );
    state = AuthState(user: user, isLoading: false);
    return user;
  }

  Future<void> logout() async {
    ref.read(assistantAvailabilityTrackerProvider).stop();
    await PushNotificationService.instance.clearToken(ref);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
