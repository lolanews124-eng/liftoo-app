import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../shared/widgets/otp_pin_input.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _otp = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_otp.length < 6) return;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: widget.email,
            otp: _otp,
            newPassword: password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go('/auth/login');
    } catch (e) {
      if (mounted) {
        if (NetworkErrors.isOffline(e)) {
          showAppErrorSnackBar(context, e);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or expired code. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: KeyboardAwareScroll(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset password',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), fontSize: 14),
                children: [
                  const TextSpan(text: 'Enter the code sent to '),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OtpPinInput(
              onChanged: (v) => _otp = v,
              onCompleted: (v) => _otp = v,
            ),
            const SizedBox(height: 24),
            const Text('New password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              scrollPadding: keyboardScrollPadding(context),
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Confirm password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              scrollPadding: keyboardScrollPadding(context),
              decoration: InputDecoration(
                hintText: 'Re-enter password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Update password',
              isLoading: _loading,
              onPressed: _otp.length == 6 ? _reset : null,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
