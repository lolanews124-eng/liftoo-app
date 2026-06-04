import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/home_feed_repository.dart';

/// Admin-managed promo banner (below Refer & Earn on home).
class HomeFeedAdBanner extends StatelessWidget {
  final HomeFeedAd ad;

  const HomeFeedAdBanner({super.key, required this.ad});

  Future<void> _onTap(BuildContext context) async {
    final link = ad.buttonLink?.trim();
    if (link == null || link.isEmpty) return;

    if (ad.buttonAction == 'route') {
      if (context.mounted) context.push(link.startsWith('/') ? link : '/$link');
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasButton = (ad.buttonLabel?.trim().isNotEmpty ?? false) && (ad.buttonLink?.trim().isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: hasButton ? () => _onTap(context) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 2.4,
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                if (ad.title != null && ad.title!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Text(
                      ad.title!,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.navy),
                    ),
                  ),
                ],
                if (hasButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () => _onTap(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(ad.buttonLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
