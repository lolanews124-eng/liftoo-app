import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/layout/screen_safe_padding.dart';
import '../../core/legal/legal_links.dart';
import '../../core/legal/legal_policies.dart';
import '../../core/network/error_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/liftoo_card.dart';

class LegalPoliciesScreen extends StatelessWidget {
  const LegalPoliciesScreen({super.key});

  Future<void> _openPolicy(BuildContext context, String slug) async {
    final opened = await openLegalPage(slug);
    if (!context.mounted) return;
    if (!opened) {
      showAppErrorSnackBar(context, Exception('Could not open policy page'));
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:support@liftoo.in');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal & policies')),
      body: ListView(
        padding: shellScrollPadding(context, top: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Transparency about how Liftoo works, how we handle your data, and your rights as a customer or assistant.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 14),
            ),
          ),
          ...kLegalPolicies.map(
            (policy) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiftooCard(
                onTap: () => _openPolicy(context, policy.slug),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            policy.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            policy.summary,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Updated ${policy.lastUpdated}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.open_in_new, size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _emailSupport,
              child: const Text(
                'Questions? Email support@liftoo.in',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
