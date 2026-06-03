import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Opens a Liftoo legal/policy page in the device browser (liftoo.in).
Future<bool> openLegalPage(String slug) async {
  final uri = Uri.parse(AppConfig.legalUrl(slug));
  return _launchExternal(uri);
}

Future<bool> openLegalIndex() async {
  final uri = Uri.parse(AppConfig.legalIndexUrl);
  return _launchExternal(uri);
}

Future<bool> _launchExternal(Uri uri) async {
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (launched) return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[Legal] launchUrl failed: $e');
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (e) {
    if (kDebugMode) debugPrint('[Legal] platformDefault failed: $e');
    return false;
  }
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
