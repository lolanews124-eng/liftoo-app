import 'dart:async';

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
      final token = await ref.read(tokenStorageProvider).getAccessToken();
      if (token == null) {
        state = const AuthState(isLoading: false);
        return;
      }
      final user = await ref
          .read(authRepositoryProvider)
          .getCurrentUser()
          .timeout(const Duration(seconds: 6));
      state = AuthState(user: user, isLoading: false);
      if (user != null) {
        unawaited(PushNotificationService.instance.syncAfterLogin(ref));
      }
    } on TimeoutException {
      state = const AuthState(isLoading: false);
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<LoginResult> signInWithEmail(String email, String password) async {
    try {
      final result = await ref.read(authRepositoryProvider).loginWithEmail(email, password);
      if (!result.requiresOtp && result.user != null) {
        state = AuthState(user: result.user, isLoading: false);
        await ref.read(pendingAuthStorageProvider).clearLoginAuth();
        await PushNotificationService.instance.syncAfterLogin(ref);
      }
      return result;
    } catch (e) {
      state = state.copyWith(error: NetworkErrors.userMessage(e));
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
    try {
      final result = await ref.read(authRepositoryProvider).verifyEmailOtp(
            email,
            otp,
            referralCode: referralCode,
          );
      state = AuthState(user: result.user, isLoading: false);
      await ref.read(pendingAuthStorageProvider).clearLoginAuth();
      await PushNotificationService.instance.syncAfterLogin(ref);
      return result;
    } catch (e) {
      state = state.copyWith(error: NetworkErrors.userMessage(e));
      rethrow;
    }
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await ref.read(authRepositoryProvider).sendPasswordResetOtp(email);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ref.read(authRepositoryProvider).resetPassword(
          email: email,
          otp: otp,
          newPassword: newPassword,
        );
  }

  Future<void> setRole(AppRole role) async {
    final user = await ref.read(authRepositoryProvider).setRole(role);
    state = AuthState(user: user, isLoading: false);
    await PushNotificationService.instance.syncAfterLogin(ref);
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
    await PushNotificationService.instance.syncAfterLogin(ref);
    return user;
  }

  Future<void> logout() async {
    ref.read(assistantAvailabilityTrackerProvider).stop();
    await PushNotificationService.instance.clearToken(ref);
    await ref.read(pendingAuthStorageProvider).clearLoginAuth();
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  Future<void> deleteAccount() async {
    ref.read(assistantAvailabilityTrackerProvider).stop();
    await PushNotificationService.instance.clearToken(ref);
    await ref.read(authRepositoryProvider).deleteAccount();
    await ref.read(pendingAuthStorageProvider).clearLoginAuth();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
