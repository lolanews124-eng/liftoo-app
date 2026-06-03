import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/hero_assistant.dart';

class HomeHeroSlide {
  final String tag;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData? icon;
  final bool showIllustration;

  const HomeHeroSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.gradientColors,
    required this.accentColor,
    this.icon,
    this.showIllustration = true,
  });
}

const _slides = [
  HomeHeroSlide(
    tag: '⚡ Instant booking',
    title: 'Shop without\ncarrying bags',
    subtitle: 'Verified assistants for malls, markets & exhibitions.',
    ctaLabel: 'Book Assistant',
    gradientColors: [Color(0xFFFFE6F0), Color(0xFFFFF8FB)],
    accentColor: AppColors.primary,
    showIllustration: true,
  ),
  HomeHeroSlide(
    tag: '🛍️ Bag carry',
    title: 'Hands-free\nshopping',
    subtitle: 'Let an assistant carry bags while you browse freely.',
    ctaLabel: 'Book now',
    gradientColors: [Color(0xFFE8F4FF), Color(0xFFF8FBFF)],
    accentColor: Color(0xFF3B82F6),
    icon: Icons.shopping_bag_outlined,
  ),
  HomeHeroSlide(
    tag: '👨‍👩‍👧 Family help',
    title: 'Help for family\n& seniors',
    subtitle: 'Trusted support at hospitals, malls and crowded places.',
    ctaLabel: 'Get help',
    gradientColors: [Color(0xFFE8F8F0), Color(0xFFF5FFFA)],
    accentColor: Color(0xFF10B981),
    icon: Icons.family_restroom_outlined,
  ),
  HomeHeroSlide(
    tag: '🎉 Events',
    title: 'Festival &\nqueue support',
    subtitle: 'Skip long lines — assistants wait so you do not have to.',
    ctaLabel: 'Find assistant',
    gradientColors: [Color(0xFFF3E8FF), Color(0xFFFBF7FF)],
    accentColor: Color(0xFF8B5CF6),
    icon: Icons.celebration_outlined,
  ),
];

class HomeHeroCarousel extends StatefulWidget {
  final VoidCallback? onBookTap;
  final void Function(int index)? onSlideChanged;

  const HomeHeroCarousel({
    super.key,
    this.onBookTap,
    this.onSlideChanged,
  });

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _pageController = PageController();
  Timer? _autoTimer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
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
      if (!mounted || !_pageController.hasClients) return;
      final next = (_current + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
    widget.onSlideChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final carouselHeight = (screenWidth * 0.50).clamp(168.0, 210.0);

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _HeroSlideCard(
              slide: _slides[index],
              onCta: widget.onBookTap,
              maxHeight: carouselHeight,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  final HomeHeroSlide slide;
  final VoidCallback? onCta;
  final double maxHeight;

  const _HeroSlideCard({
    required this.slide,
    this.onCta,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth < 360 ? 14.0 : 16.0;
    final cardInnerPad = screenWidth < 360 ? 14.0 : 18.0;
    final cardWidth = screenWidth - (horizontalPad * 2);

    final showArt = slide.showIllustration;
    final artWidth = showArt ? (cardWidth * 0.34).clamp(88.0, 118.0) : 0.0;
    final artHeight = (maxHeight - cardInnerPad * 2).clamp(100.0, 140.0);
    final titleSize = screenWidth < 340 ? 18.0 : (screenWidth < 380 ? 19.0 : 21.0);
    final compact = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: Container(
        height: maxHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: slide.accentColor.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: slide.accentColor.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardInnerPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: slide.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        slide.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: slide.accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10 : 11,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          slide.subtitle,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.95),
                            fontSize: compact ? 11 : 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    if (onCta != null) ...[
                      SizedBox(height: compact ? 6 : 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _HeroCtaButton(
                          label: slide.ctaLabel,
                          color: slide.accentColor,
                          compact: compact,
                          onTap: onCta!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showArt) ...[
                SizedBox(width: compact ? 6 : 8),
                SizedBox(
                  width: artWidth,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: artWidth,
                        height: artHeight,
                        child: const HeroAssistantIllustration(),
                      ),
                    ),
                  ),
                ),
              ] else if (slide.icon != null) ...[
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: math.min(64, artWidth > 0 ? artWidth : 64),
                    height: math.min(64, artWidth > 0 ? artWidth : 64),
                    decoration: BoxDecoration(
                      color: slide.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slide.icon, size: 30, color: slide.accentColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCtaButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _HeroCtaButton({
    required this.label,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBtnWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBtnWidth),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 8 : 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 4 : 6),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: compact ? 14 : 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
