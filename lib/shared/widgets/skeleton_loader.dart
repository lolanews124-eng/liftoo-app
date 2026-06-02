import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const SkeletonBox(width: 100, height: 28, radius: 8),
            const Spacer(),
            const SkeletonBox(width: 40, height: 40, radius: 12),
            const SizedBox(width: 8),
            const SkeletonBox(width: 56, height: 40, radius: 12),
          ],
        ),
        const SizedBox(height: 8),
        const SkeletonBox(height: 188, radius: 22),
        const SizedBox(height: 12),
        const SkeletonBox(width: 80, height: 8, radius: 4),
        const SizedBox(height: 16),
        const SkeletonBox(height: 260, radius: 22),
        const SizedBox(height: 20),
        const SkeletonBox(width: 120, height: 18, radius: 6),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                child: const SkeletonBox(width: 72, height: 76, radius: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(height: 40, radius: 20),
      ],
    );
  }
}

class ListScreenSkeleton extends StatelessWidget {
  final int count;

  const ListScreenSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonBox(height: 88, radius: 16),
    );
  }
}

class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: SkeletonBox(height: 120, radius: 18),
    );
  }
}

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonBox(width: 88, height: 88, radius: 44),
        const SizedBox(height: 12),
        const SkeletonBox(width: 140, height: 20, radius: 8),
        const SizedBox(height: 8),
        const SkeletonBox(width: 100, height: 14, radius: 6),
      ],
    );
  }
}
