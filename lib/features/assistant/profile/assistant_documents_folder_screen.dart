import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/assistant_verification_model.dart';
import '../../../shared/widgets/liftoo_card.dart';
import 'assistant_address_form_sheet.dart';

class AssistantDocumentsFolderScreen extends ConsumerWidget {
  final VerificationBundleModel bundle;

  const AssistantDocumentsFolderScreen({super.key, required this.bundle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitted = bundle.submittedDocuments;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My documents'),
        backgroundColor: AppColors.surface,
      ),
      body: submitted.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No documents yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your verification documents from Profile. Once submitted, they appear here for viewing only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LiftooCard(
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verified documents cannot be edited. Contact support if you need changes.',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.95), height: 1.35, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...submitted.map((doc) => _DocumentFolderTile(doc: doc, onTap: () => _showDetail(context, doc))),
              ],
            ),
    );
  }

  void _showDetail(BuildContext context, VerificationDocumentModel doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(doc.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _StatusChip(status: doc.status),
            const SizedBox(height: 16),
            if (doc.fileUrl != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(doc.fileUrl!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (doc.type == VerificationDocType.fullAddress && doc.metadata != null) ...[
              ..._addressDetailRows(AssistantAddressData.fromMetadata(doc.metadata)),
              const SizedBox(height: 12),
            ] else if (doc.textValue != null) ...[
              const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(doc.textValue!, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 12),
            ],
            if (doc.metadata != null && doc.type == VerificationDocType.bankDetails) ...[
              const Text('Bank account', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('****${(doc.metadata!['accountNumber'] as String?)?.substring(((doc.metadata!['accountNumber'] as String?)?.length ?? 4) - 4)}'),
              const SizedBox(height: 8),
              Text('IFSC: ${doc.metadata!['ifsc'] ?? '—'}'),
              const SizedBox(height: 12),
            ],
            if (doc.uploadedAt != null)
              Text('Submitted: ${DateFormat('d MMM yyyy, h:mm a').format(doc.uploadedAt!)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (doc.verifiedAt != null)
              Text('Verified: ${DateFormat('d MMM yyyy').format(doc.verifiedAt!)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
            if (doc.adminNote != null && doc.isRejected) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Admin note: ${doc.adminNote}', style: const TextStyle(color: AppColors.error)),
              ),
            ],
            const SizedBox(height: 8),
            const Text('View only — editing is disabled after submission.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  List<Widget> _addressDetailRows(AssistantAddressData addr) {
    Widget row(String label, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35))),
          ],
        ),
      );
    }

    return [
      const Text('Address details', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      row('Full address', addr.fullAddress),
      row('Post / area', addr.post),
      row('Police station', addr.policeStation),
      row('Block', addr.block),
      row('District', addr.district),
      row('State', addr.state),
      row('Country', addr.country),
      row('Pincode', addr.pincode),
    ];
  }
}

class _DocumentFolderTile extends StatelessWidget {
  final VerificationDocumentModel doc;
  final VoidCallback onTap;

  const _DocumentFolderTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiftooCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(_iconFor(doc.type), color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (doc.uploadedAt != null)
                    Text(DateFormat('d MMM yyyy').format(doc.uploadedAt!), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            _StatusChip(status: doc.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(VerificationDocType type) => switch (type) {
        VerificationDocType.profilePhoto || VerificationDocType.selfie => Icons.face_outlined,
        VerificationDocType.fullAddress => Icons.home_outlined,
        VerificationDocType.aadhaar => Icons.badge_outlined,
        VerificationDocType.pan => Icons.credit_card_outlined,
        VerificationDocType.bankDetails => Icons.account_balance_outlined,
        _ => Icons.photo_camera_outlined,
      };
}

class _StatusChip extends StatelessWidget {
  final VerificationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      VerificationStatus.notSubmitted => ('Not uploaded', AppColors.textSecondary),
      VerificationStatus.pending => ('Pending review', AppColors.warning),
      VerificationStatus.verified => ('Verified', AppColors.success),
      VerificationStatus.rejected => ('Rejected', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
