import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Opens a Liftoo legal/policy page on the customer web app.
Future<bool> openLegalPage(String slug) async {
  final uri = Uri.parse(AppConfig.legalUrl(slug));
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<bool> openLegalIndex() async {
  final uri = Uri.parse(AppConfig.legalIndexUrl);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Policy slugs matching customer-web `/legal/:slug` routes.
abstract final class LegalSlugs {
  static const privacyPolicy = 'privacy-policy';
  static const termsOfService = 'terms-of-service';
  static const refundCancellation = 'refund-cancellation';
  static const assistantPartnerAgreement = 'assistant-partner-agreement';
  static const acceptableUse = 'acceptable-use';
  static const accountDeletion = 'account-deletion';
  static const cookiePolicy = 'cookie-policy';
}
