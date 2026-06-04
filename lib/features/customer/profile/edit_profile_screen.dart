import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _photoPath = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var avatarUrl = _photoPath;
      if (avatarUrl != null &&
          !avatarUrl.startsWith('http') &&
          !avatarUrl.startsWith('upload://')) {
        final file = File(avatarUrl);
        if (await file.exists()) {
          avatarUrl = await ref.read(apiClientProvider).uploadImageFile(avatarUrl);
        }
      }

      await ref.read(authProvider.notifier).completeProfile(
            name: name,
            phone: phone,
            avatarUrl: avatarUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ProfileAvatar(
              name: _nameController.text,
              phone: _phoneController.text,
              avatarUrl: _photoPath,
              radius: 52,
              editable: true,
              onPhotoPicked: (path) => setState(() => _photoPath = path),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Tap photo to change', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixText: '+91 ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: user?.email ?? ''),
            decoration: const InputDecoration(
              labelText: 'Email (cannot be changed)',
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Save changes',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
