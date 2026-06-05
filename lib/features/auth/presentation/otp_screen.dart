import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/otp_pin_input.dart';
import '../providers/auth_provider.dart';
import 'auth_navigation.dart';
import 'otp_login_args.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final OtpLoginArgs? args;

  const OtpScreen({super.key, this.args});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _loading = false;
  bool _resending = false;
  int _resendSeconds = 30;
  String _otp = '';
  OtpLoginArgs? _resolvedArgs;
  bool _checkingArgs = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _resolveArgs();
  }

  Future<void> _resolveArgs() async {
    if (widget.args != null) {
      setState(() {
        _resolvedArgs = widget.args;
        _checkingArgs = false;
      });
      return;
    }
    final pending = await ref.read(pendingAuthStorageProvider).peekLoginAuth();
    if (!mounted) return;
    if (pending == null) {
      context.go('/auth/login');
      return;
    }
    setState(() {
      _resolvedArgs = OtpLoginArgs(email: pending.email, password: pending.password);
      _checkingArgs = false;
    });
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 30));
      return _resendSeconds > 0;
    });
  }

  Future<void> _resend() async {
    final args = _resolvedArgs;
    if (args == null || _resendSeconds > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).resendEmailOtp(
            args.email,
            args.password,
          );
      if (mounted) {
        setState(() => _resendSeconds = 30);
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent again')),
        );
      }
    } catch (_) {
      if (mounted) {
        showAppErrorSnackBar(context, NetworkErrors.noInternet);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final args = _resolvedArgs;
    if (args == null || _otp.length < 6) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final referralCode = await ref.read(referralStorageProvider).consumePendingCode();
      final result = await ref.read(authProvider.notifier).verifyEmailOtp(
            args.email,
            _otp,
            referralCode: referralCode,
            password: args.password,
          );
      if (!mounted) return;
      navigateAfterAuth(context, result.user);
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        if (NetworkErrors.isOffline(e)) {
          showAppErrorSnackBar(context, e);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect code. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingArgs || _resolvedArgs == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final email = _resolvedArgs!.email;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), fontSize: 14),
                children: [
                  const TextSpan(text: 'Enter the 6-digit code sent to '),
                  TextSpan(
                    text: email,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            OtpPinInput(
              onChanged: (v) => _otp = v,
              onCompleted: (v) {
                _otp = v;
                _verify();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _resendSeconds == 0 && !_resending ? _resend : null,
                child: Text(
                  _resendSeconds > 0
                      ? 'Resend code in ${_resendSeconds}s'
                      : (_resending ? 'Sending…' : 'Resend code'),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Verify & Continue',
              isLoading: _loading,
              onPressed: _otp.length == 6 ? _verify : null,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
