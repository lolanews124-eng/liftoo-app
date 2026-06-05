import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/home_feed_repository.dart';

/// Admin-managed promo carousel (below Refer & Earn). Auto-slides through active ads.
class HomeFeedAdCarousel extends StatefulWidget {
  final List<HomeFeedAd> ads;

  const HomeFeedAdCarousel({super.key, required this.ads});

  @override
  State<HomeFeedAdCarousel> createState() => _HomeFeedAdCarouselState();
}

class _HomeFeedAdCarouselState extends State<HomeFeedAdCarousel> {
  final _pageController = PageController();
  Timer? _autoTimer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ads.length > 1) _startAutoSlide();
  }

  @override
  void didUpdateWidget(HomeFeedAdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ads.length > 1 && oldWidget.ads.length <= 1) {
      _startAutoSlide();
    } else if (widget.ads.length <= 1) {
      _autoTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || widget.ads.length < 2) return;
      final next = (_current + 1) % widget.ads.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openAd(BuildContext context, HomeFeedAd ad) async {
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
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final bannerHeight = (width * 0.42).clamp(150.0, 190.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.ads.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) => _AdSlide(
                ad: widget.ads[index],
                height: bannerHeight,
                onTap: () => _openAd(context, widget.ads[index]),
              ),
            ),
          ),
          if (widget.ads.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.ads.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdSlide extends StatelessWidget {
  final HomeFeedAd ad;
  final double height;
  final VoidCallback onTap;

  const _AdSlide({
    required this.ad,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = ad.title != null && ad.title!.trim().isNotEmpty;
    final hasButton =
        (ad.buttonLabel?.trim().isNotEmpty ?? false) && (ad.buttonLink?.trim().isNotEmpty ?? false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navy, Color(0xFF002A5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 36),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (hasTitle || hasButton)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasTitle)
                      Expanded(
                        child: Text(
                          ad.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                          ),
                        ),
                      ),
                    if (hasTitle && hasButton) const SizedBox(width: 12),
                    if (hasButton)
                      Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.45),
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ad.buttonLabel!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
