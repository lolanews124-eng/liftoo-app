import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/legal/legal_links.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../providers/auth_provider.dart';
import 'auth_navigation.dart';
import 'widgets/login_brand_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _referralExpanded = false;
  String? _referralHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReferral());
  }

  Future<void> _loadReferral() async {
    final uriRef = GoRouterState.of(context).uri.queryParameters['ref'];
    if (uriRef != null && uriRef.isNotEmpty) {
      await ref.read(referralStorageProvider).savePendingCode(uriRef);
      if (mounted) {
        setState(() {
          _referralExpanded = true;
          _referralController.text = uriRef;
          _referralHint = 'Referral code applied from invite link';
        });
      }
      return;
    }
    final pending = await ref.read(referralStorageProvider).peekPendingCode();
    if (pending != null && mounted) {
      setState(() {
        _referralExpanded = true;
        _referralController.text = pending;
        _referralHint = 'Referral code applied from invite link';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final referral = _referralController.text.trim();
      if (referral.isNotEmpty) {
        await ref.read(referralStorageProvider).savePendingCode(referral);
      }
      final result = await ref.read(authProvider.notifier).signInWithEmail(email, password);
      if (!mounted) return;
      if (result.requiresOtp) {
        await ref.read(pendingAuthStorageProvider).saveLoginAuth(email: email, password: password);
        context.go('/auth/otp');
      } else if (result.user != null) {
        navigateAfterAuth(context, result.user!);
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({required String hint, required IconData prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefix, color: AppColors.primary),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollPad = keyboardScrollPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardAwareScroll(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LoginBrandHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      scrollPadding: scrollPad,
                      decoration: _fieldDecoration(hint: 'you@example.com', prefix: Icons.email_outlined),
                    ),
                    const SizedBox(height: 18),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      scrollPadding: scrollPad,
                      decoration: _fieldDecoration(
                        hint: 'At least 6 characters',
                        prefix: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : () => context.push('/auth/forgot-password'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _referralExpanded = !_referralExpanded),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Have a Referral Code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _referralExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _referralController,
                          textCapitalization: TextCapitalization.characters,
                          scrollPadding: scrollPad,
                          decoration: InputDecoration(
                            hintText: 'Enter referral code',
                            prefixIcon: const Icon(Icons.card_giftcard_outlined, color: AppColors.primary),
                            helperText: _referralHint,
                          ),
                        ),
                      ),
                      crossFadeState:
                          _referralExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                      sizeCurve: Curves.easeOut,
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Sign in', isLoading: _loading, onPressed: _continue),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => openLegalPage(LegalSlugs.termsOfService),
                                child: const Text(
                                  'Terms of Service',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => openLegalPage(LegalSlugs.privacyPolicy),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
