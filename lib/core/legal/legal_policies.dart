/// Metadata for Liftoo legal pages (content lives on liftoo.in / customer-web).
class LegalPolicyMeta {
  final String slug;
  final String title;
  final String summary;
  final String lastUpdated;

  const LegalPolicyMeta({
    required this.slug,
    required this.title,
    required this.summary,
    required this.lastUpdated,
  });
}

/// All policy slugs and titles — keep in sync with customer-web `src/legal/policies.ts`.
const kLegalPolicies = <LegalPolicyMeta>[
  LegalPolicyMeta(
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    summary: 'How we collect, use, and protect your personal data.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'terms-of-service',
    title: 'Terms of Service',
    summary: 'Rules for using the Liftoo platform as a customer or user.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'refund-cancellation',
    title: 'Refund & Cancellation Policy',
    summary: 'When bookings can be cancelled and how refunds are processed.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'assistant-partner-agreement',
    title: 'Assistant Partner Agreement',
    summary: 'Terms for individuals providing services through Liftoo as assistants.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'acceptable-use',
    title: 'Acceptable Use Policy',
    summary: 'Standards for chat, reviews, and platform behaviour.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'account-deletion',
    title: 'Account Deletion Policy',
    summary: 'How to delete your account and what happens to your data.',
    lastUpdated: '30 May 2026',
  ),
  LegalPolicyMeta(
    slug: 'cookie-policy',
    title: 'Cookie Policy',
    summary: 'How the Liftoo website uses cookies and similar technologies.',
    lastUpdated: '30 May 2026',
  ),
];
