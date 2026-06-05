import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/permissions/app_permissions_service.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../providers/auth_provider.dart';
import 'setup_profile_args.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  final SetupProfileArgs args;

  const SetupProfileScreen({super.key, this.args = const SetupProfileArgs()});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  String? _photoName;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (!await AppPermissionsService.ensureMediaAccess()) return;
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _photoName = file.name.isNotEmpty ? file.name : 'photo.jpg');
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).completeProfile(
            name: name,
            phone: phone,
            avatarUrl: _photoName != null ? 'upload://$_photoName' : null,
          );
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      if (user?.activeRole == null) {
        context.go('/role-selection');
      } else if (user!.activeRole == 'assistant') {
        context.go('/assistant');
      } else {
        context.go('/customer');
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Complete your profile'),
      ),
      body: SafeArea(
        child: KeyboardAwareScroll(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Liftoo',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your name and mobile number. We use your number for booking calls and updates.',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.45),
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primaryLight,
                        child: _photoName != null
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 40)
                            : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _photoName != null ? 'Photo selected (optional)' : 'Add photo (optional)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Full name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                scrollPadding: keyboardScrollPadding(context),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                scrollPadding: keyboardScrollPadding(context),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '10-digit number',
                  prefixText: '+91 ',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(label: 'Save & continue', isLoading: _loading, onPressed: _save),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
