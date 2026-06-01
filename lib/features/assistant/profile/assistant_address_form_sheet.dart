import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class AssistantAddressData {
  final String fullAddress;
  final String post;
  final String policeStation;
  final String block;
  final String district;
  final String state;
  final String country;
  final String pincode;

  const AssistantAddressData({
    required this.fullAddress,
    required this.post,
    required this.policeStation,
    required this.block,
    required this.district,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory AssistantAddressData.fromMetadata(Map<String, dynamic>? meta) {
    if (meta == null) {
      return const AssistantAddressData(
        fullAddress: '',
        post: '',
        policeStation: '',
        block: '',
        district: '',
        state: '',
        country: 'India',
        pincode: '',
      );
    }
    return AssistantAddressData(
      fullAddress: meta['fullAddress'] as String? ?? '',
      post: meta['post'] as String? ?? '',
      policeStation: meta['policeStation'] as String? ?? '',
      block: meta['block'] as String? ?? '',
      district: meta['district'] as String? ?? '',
      state: meta['state'] as String? ?? '',
      country: meta['country'] as String? ?? 'India',
      pincode: meta['pincode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMetadata() => {
        'fullAddress': fullAddress.trim(),
        'post': post.trim(),
        'policeStation': policeStation.trim(),
        'block': block.trim(),
        'district': district.trim(),
        'state': state.trim(),
        'country': country.trim(),
        'pincode': pincode.trim(),
      };

  String get formattedSummary {
    final parts = [
      fullAddress,
      if (post.isNotEmpty) post,
      if (policeStation.isNotEmpty) 'PS: $policeStation',
      if (block.isNotEmpty) block,
      district,
      state,
      country,
      if (pincode.isNotEmpty) 'PIN $pincode',
    ].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  bool get isValid =>
      fullAddress.trim().isNotEmpty &&
      district.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      country.trim().isNotEmpty &&
      pincode.trim().length == 6;
}

/// Opens a styled bottom sheet to collect full residential address.
Future<AssistantAddressData?> showAssistantAddressForm(
  BuildContext context, {
  AssistantAddressData? initial,
}) {
  return showModalBottomSheet<AssistantAddressData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AssistantAddressFormSheet(initial: initial ?? const AssistantAddressData(
      fullAddress: '',
      post: '',
      policeStation: '',
      block: '',
      district: '',
      state: '',
      country: 'India',
      pincode: '',
    )),
  );
}

class _AssistantAddressFormSheet extends StatefulWidget {
  final AssistantAddressData initial;

  const _AssistantAddressFormSheet({required this.initial});

  @override
  State<_AssistantAddressFormSheet> createState() => _AssistantAddressFormSheetState();
}

class _AssistantAddressFormSheetState extends State<_AssistantAddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullAddress;
  late final TextEditingController _post;
  late final TextEditingController _policeStation;
  late final TextEditingController _block;
  late final TextEditingController _district;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _pincode;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _fullAddress = TextEditingController(text: i.fullAddress);
    _post = TextEditingController(text: i.post);
    _policeStation = TextEditingController(text: i.policeStation);
    _block = TextEditingController(text: i.block);
    _district = TextEditingController(text: i.district);
    _state = TextEditingController(text: i.state);
    _country = TextEditingController(text: i.country.isEmpty ? 'India' : i.country);
    _pincode = TextEditingController(text: i.pincode);
  }

  @override
  void dispose() {
    _fullAddress.dispose();
    _post.dispose();
    _policeStation.dispose();
    _block.dispose();
    _district.dispose();
    _state.dispose();
    _country.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AssistantAddressData(
        fullAddress: _fullAddress.text,
        post: _post.text,
        policeStation: _policeStation.text,
        block: _block.text,
        district: _district.text,
        state: _state.text,
        country: _country.text,
        pincode: _pincode.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      height: maxH,
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.home_work_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Full address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('For verification & security', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        _field(
                          controller: _fullAddress,
                          label: 'Full address',
                          hint: 'House / flat no., street, landmark',
                          maxLines: 2,
                          required: true,
                        ),
                        _field(controller: _post, label: 'Post / area', hint: 'e.g. Boring Road, Kankarbagh'),
                        _field(controller: _policeStation, label: 'Police station', hint: 'Nearest police station'),
                        _field(controller: _block, label: 'Block / tehsil', hint: 'Block or tehsil name'),
                        Row(
                          children: [
                            Expanded(child: _field(controller: _district, label: 'District', required: true)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                controller: _pincode,
                                label: 'Pincode',
                                required: true,
                                keyboard: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                                validator: (v) {
                                  if (v == null || v.length != 6) return '6 digits';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _field(controller: _state, label: 'State', required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(controller: _country, label: 'Country', required: true)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Address will be sent for admin verification. Once verified, it cannot be edited.',
                                  style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Submit for admin review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
