import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/permissions/app_permissions_service.dart';
import '../../../core/network/network_errors.dart';
import '../../../core/network/error_snackbar.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/network_error_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/assistant_verification_model.dart';
import '../../../shared/widgets/liftoo_card.dart';
import 'assistant_address_form_sheet.dart';
import 'assistant_bank_form_sheet.dart';
import 'assistant_documents_folder_screen.dart';

class AssistantVerificationScreen extends ConsumerStatefulWidget {
  const AssistantVerificationScreen({super.key});

  @override
  ConsumerState<AssistantVerificationScreen> createState() => _AssistantVerificationScreenState();
}

class _AssistantVerificationScreenState extends ConsumerState<AssistantVerificationScreen> {
  VerificationBundleModel? _bundle;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await ref.read(assistantVerificationRepositoryProvider).getVerification();
      if (mounted) setState(() => _bundle = bundle);
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrors.userMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDocumentTap(VerificationDocumentModel doc) async {
    if (doc.isLocked) {
      if (doc.isPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Under admin review — cannot edit right now')),
        );
      } else if (doc.isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already verified — contact support to change')),
        );
      }
      return;
    }

    if (doc.type == VerificationDocType.fullAddress) {
      await _submitAddress(doc);
      return;
    }
    if (doc.type == VerificationDocType.bankDetails) {
      await _submitBank(doc);
      return;
    }
    await _submitPhoto(doc.type);
  }

  Future<void> _submitPhoto(VerificationDocType type) async {
    if (!await AppPermissionsService.ensureMediaAccess()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo access is required to upload documents')),
        );
      }
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final url = await ref.read(apiClientProvider).uploadImageFile(file.path);
      if (!mounted) return;
      final bundle = await ref.read(assistantVerificationRepositoryProvider).submitDocument(
            type: type,
            fileUrl: url,
          );
      if (mounted) {
        setState(() => _bundle = bundle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for admin verification')),
        );
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitAddress(VerificationDocumentModel doc) async {
    final initial = doc.metadata != null
        ? AssistantAddressData.fromMetadata(doc.metadata)
        : AssistantAddressData(fullAddress: doc.textValue ?? '', post: '', policeStation: '', block: '', district: '', state: '', country: 'India', pincode: '');

    final data = await showAssistantAddressForm(context, initial: initial);
    if (data == null || !data.isValid || !mounted) return;

    await _submit(
      VerificationDocType.fullAddress,
      textValue: data.formattedSummary,
      metadata: data.toMetadata(),
    );
  }

  Future<void> _submitBank(VerificationDocumentModel doc) async {
    final data = await showAssistantBankForm(
      context,
      initial: AssistantBankData.fromMetadata(doc.metadata),
    );
    if (data == null || !data.isValid || !mounted) return;

    setState(() => _submitting = true);
    try {
      final url = await ref.read(apiClientProvider).uploadImageFile(data.passbookPath!);
      if (!mounted) return;
      final bundle = await ref.read(assistantVerificationRepositoryProvider).submitDocument(
            type: VerificationDocType.bankDetails,
            fileUrl: url,
            metadata: data.toMetadata(),
          );
      if (mounted) {
        setState(() => _bundle = bundle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for admin verification')),
        );
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit(
    VerificationDocType type, {
    String? fileUrl,
    String? textValue,
    Map<String, dynamic>? metadata,
  }) async {
    setState(() => _submitting = true);
    try {
      final bundle = await ref.read(assistantVerificationRepositoryProvider).submitDocument(
            type: type,
            fileUrl: fileUrl,
            textValue: textValue,
            metadata: metadata,
          );
      if (mounted) {
        setState(() => _bundle = bundle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for admin verification')),
        );
      }
    } catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Verification & KYC'),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            NetworkErrorState(
                              message: _error,
                              offline: _error == NetworkErrors.noInternet,
                              onRetry: _load,
                            ),
                          ],
                        )
                      : bundle == null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No verification data available')),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildInfoBanner(),
                            const SizedBox(height: 16),
                            _buildProgressCard(bundle.summary),
                            const SizedBox(height: 20),
                            _buildSectionTitle('Personal'),
                            _docTile(bundle.doc(VerificationDocType.profilePhoto)!),
                            _docTile(bundle.doc(VerificationDocType.fullAddress)!),
                            const SizedBox(height: 20),
                            _buildSectionTitle('KYC documents'),
                            _docTile(bundle.doc(VerificationDocType.aadhaar)!),
                            _docTile(bundle.doc(VerificationDocType.pan)!),
                            _docTile(bundle.doc(VerificationDocType.selfie)!),
                            _docTile(bundle.doc(VerificationDocType.bankDetails)!),
                            const SizedBox(height: 20),
                            _buildSectionTitle('Security photos', subtitle: 'Upload 5 photos for identity verification'),
                            _buildSecurityGrid(bundle.securityPhotos),
                            const SizedBox(height: 20),
                            LiftooCard(
                              onTap: bundle.submittedDocuments.isEmpty
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => AssistantDocumentsFolderScreen(bundle: bundle),
                                        ),
                                      ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.folder_outlined, color: AppColors.charcoal),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('My documents folder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        Text(
                                          '${bundle.submittedDocuments.length} document(s) • view only',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                if (_submitting)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
              ],
            ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload all documents for admin verification. Once verified, documents are locked and cannot be edited.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(VerificationSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, Color(0xFF002A5C)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification progress', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${summary.completionPercent}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${summary.verifiedCount}/${summary.totalRequired} verified', style: const TextStyle(color: Colors.white60)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.completionPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: AppColors.primary,
            ),
          ),
          if (summary.pendingCount > 0) ...[
            const SizedBox(height: 10),
            Text('${summary.pendingCount} pending admin review', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _docTile(VerificationDocumentModel doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LiftooCard(
        onTap: () => _onDocumentTap(doc),
        child: Row(
          children: [
            _docIcon(doc),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(_statusLabel(doc.status), style: TextStyle(fontSize: 12, color: _statusColor(doc.status), fontWeight: FontWeight.w600)),
                  if (doc.isRejected && doc.adminNote != null)
                    Text(doc.adminNote!, style: const TextStyle(fontSize: 11, color: AppColors.error)),
                ],
              ),
            ),
            if (doc.canEdit)
              const Text('Upload', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
            else if (doc.isVerified)
              const Icon(Icons.verified, color: AppColors.success, size: 22)
            else if (doc.isPending)
              const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22)
            else
              const Icon(Icons.refresh, color: AppColors.error, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityGrid(List<VerificationDocumentModel> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final doc = photos[i];
        return GestureDetector(
          onTap: () => _onDocumentTap(doc),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _statusColor(doc.status).withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  doc.isVerified ? Icons.check_circle : Icons.add_a_photo_outlined,
                  color: _statusColor(doc.status),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text('Photo ${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text(_statusLabel(doc.status), style: TextStyle(fontSize: 10, color: _statusColor(doc.status)), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _docIcon(VerificationDocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Icon(switch (doc.type) {
        VerificationDocType.profilePhoto => Icons.person_outline,
        VerificationDocType.fullAddress => Icons.home_outlined,
        VerificationDocType.aadhaar => Icons.badge_outlined,
        VerificationDocType.pan => Icons.credit_card_outlined,
        VerificationDocType.selfie => Icons.face_outlined,
        VerificationDocType.bankDetails => Icons.account_balance_outlined,
        _ => Icons.upload_file_outlined,
      }, color: AppColors.primary),
    );
  }

  String _statusLabel(VerificationStatus s) => switch (s) {
        VerificationStatus.notSubmitted => 'Not uploaded',
        VerificationStatus.pending => 'Pending admin review',
        VerificationStatus.verified => 'Verified • locked',
        VerificationStatus.rejected => 'Rejected • re-upload',
      };

  Color _statusColor(VerificationStatus s) => switch (s) {
        VerificationStatus.notSubmitted => AppColors.textSecondary,
        VerificationStatus.pending => AppColors.warning,
        VerificationStatus.verified => AppColors.success,
        VerificationStatus.rejected => AppColors.error,
      };
}
