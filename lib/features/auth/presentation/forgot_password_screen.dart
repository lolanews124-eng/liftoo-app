import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).sendPasswordResetOtp(email);
      if (!mounted) return;
      context.push('/auth/reset-password', extra: email);
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
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
              'Forgot password?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we will send a 6-digit code to reset your password.',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.45),
            ),
            const SizedBox(height: 28),
            const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              scrollPadding: keyboardScrollPadding(context),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(label: 'Send reset code', isLoading: _loading, onPressed: _sendCode),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
