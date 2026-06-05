import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/permissions/app_permissions_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';

class AssistantBankData {
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String? passbookPath;

  const AssistantBankData({
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    this.passbookPath,
  });

  factory AssistantBankData.fromMetadata(Map<String, dynamic>? meta) {
    if (meta == null) {
      return const AssistantBankData(
        accountHolderName: '',
        bankName: '',
        accountNumber: '',
        ifsc: '',
      );
    }
    return AssistantBankData(
      accountHolderName: meta['accountHolderName'] as String? ?? '',
      bankName: meta['bankName'] as String? ?? '',
      accountNumber: meta['accountNumber'] as String? ?? '',
      ifsc: meta['ifsc'] as String? ?? '',
    );
  }

  bool get isValid =>
      accountHolderName.trim().isNotEmpty &&
      bankName.trim().isNotEmpty &&
      accountNumber.trim().length >= 8 &&
      ifsc.trim().length >= 8 &&
      passbookPath != null &&
      passbookPath!.isNotEmpty;

  Map<String, dynamic> toMetadata() => {
        'accountHolderName': accountHolderName.trim(),
        'bankName': bankName.trim(),
        'accountNumber': accountNumber.trim(),
        'ifsc': ifsc.trim().toUpperCase(),
      };
}

Future<AssistantBankData?> showAssistantBankForm(
  BuildContext context, {
  AssistantBankData? initial,
}) {
  return showModalBottomSheet<AssistantBankData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _BankFormSheet(initial: initial ?? const AssistantBankData(
      accountHolderName: '',
      bankName: '',
      accountNumber: '',
      ifsc: '',
    )),
  );
}

class _BankFormSheet extends StatefulWidget {
  final AssistantBankData initial;

  const _BankFormSheet({required this.initial});

  @override
  State<_BankFormSheet> createState() => _BankFormSheetState();
}

class _BankFormSheetState extends State<_BankFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bankCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _ifscCtrl;
  String? _passbookPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.accountHolderName);
    _bankCtrl = TextEditingController(text: widget.initial.bankName);
    _accountCtrl = TextEditingController(text: widget.initial.accountNumber);
    _ifscCtrl = TextEditingController(text: widget.initial.ifsc);
    _passbookPath = widget.initial.passbookPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPassbook() async {
    if (!await AppPermissionsService.ensureMediaAccess()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo access is required to upload passbook')),
        );
      }
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _passbookPath = file.path);
  }

  void _submit() {
    final data = AssistantBankData(
      accountHolderName: _nameCtrl.text,
      bankName: _bankCtrl.text,
      accountNumber: _accountCtrl.text,
      ifsc: _ifscCtrl.text,
      passbookPath: _passbookPath,
    );
    if (!data.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and upload passbook photo')),
      );
      return;
    }
    Navigator.pop(context, data);
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: keyboardInsetPadding(context, base: const EdgeInsets.fromLTRB(20, 12, 20, 24)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bank details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Enter your account details and upload a clear passbook or cheque photo.',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              scrollPadding: keyboardScrollPadding(context),
              decoration: _fieldDecoration('Account holder name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankCtrl,
              textCapitalization: TextCapitalization.words,
              scrollPadding: keyboardScrollPadding(context),
              decoration: _fieldDecoration('Bank name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              scrollPadding: keyboardScrollPadding(context),
              decoration: _fieldDecoration('Account number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              scrollPadding: keyboardScrollPadding(context),
              decoration: _fieldDecoration('IFSC code'),
            ),
            const SizedBox(height: 16),
            const Text('Passbook photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            if (_passbookPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_passbookPath!), height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _pickPassbook,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(_passbookPath == null ? 'Upload passbook photo' : 'Change photo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
