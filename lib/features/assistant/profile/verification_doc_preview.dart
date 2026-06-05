import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

bool verificationFileIsImage(String? url) {
  if (url == null || url.isEmpty || url.startsWith('upload://')) return false;
  final lower = url.toLowerCase();
  return lower.contains('/uploads/') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

class VerificationDocImagePreview extends StatelessWidget {
  final String imageUrl;
  final double height;

  const VerificationDocImagePreview({
    super.key,
    required this.imageUrl,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          height: height,
          color: AppColors.surface,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          height: height,
          color: AppColors.primaryLight,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
