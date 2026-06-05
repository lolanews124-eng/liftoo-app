import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/media_url.dart';
import '../../core/permissions/app_permissions_service.dart';
import '../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final double radius;
  final bool editable;
  final ValueChanged<String?>? onPhotoPicked;

  const ProfileAvatar({
    super.key,
    this.name,
    this.phone,
    this.avatarUrl,
    this.radius = 40,
    this.editable = false,
    this.onPhotoPicked,
  });

  String get _initial => (name ?? phone ?? 'U')[0].toUpperCase();

  bool get _hasNetworkImage =>
      avatarUrl != null &&
      (avatarUrl!.startsWith('http') || avatarUrl!.startsWith('/')) &&
      !avatarUrl!.startsWith('upload://');

  bool get _hasLocalFile {
    if (avatarUrl == null || avatarUrl!.startsWith('http') || avatarUrl!.startsWith('upload://')) return false;
    try {
      return File(avatarUrl!).existsSync();
    } catch (_) {
      return false;
    }
  }

  ImageProvider? get _imageProvider {
    if (_hasNetworkImage) return CachedNetworkImageProvider(resolveMediaUrl(avatarUrl!));
    if (_hasLocalFile) return FileImage(File(avatarUrl!));
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    if (!editable || onPhotoPicked == null) return;
    if (!await AppPermissionsService.ensureMediaAccess()) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) onPhotoPicked!(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: _imageProvider,
      child: _imageProvider != null
          ? null
          : Text(_initial, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: AppColors.primary)),
    );

    if (!editable) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(onTap: () => _pick(context), child: avatar),
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: size * 0.18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
