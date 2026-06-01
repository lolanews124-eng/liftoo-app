enum VerificationDocType {
  profilePhoto('profile_photo'),
  fullAddress('full_address'),
  aadhaar('aadhaar'),
  pan('pan'),
  selfie('selfie'),
  bankDetails('bank_details'),
  securityPhoto1('security_photo_1'),
  securityPhoto2('security_photo_2'),
  securityPhoto3('security_photo_3'),
  securityPhoto4('security_photo_4'),
  securityPhoto5('security_photo_5');

  const VerificationDocType(this.apiValue);
  final String apiValue;

  static VerificationDocType? fromApi(String value) {
    for (final t in values) {
      if (t.apiValue == value) return t;
    }
    return null;
  }
}

enum VerificationStatus {
  notSubmitted('not_submitted'),
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const VerificationStatus(this.apiValue);
  final String apiValue;

  static VerificationStatus fromApi(String? value) {
    return values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => VerificationStatus.notSubmitted,
    );
  }
}

class VerificationDocumentModel {
  final VerificationDocType type;
  final String label;
  final VerificationStatus status;
  final String? fileUrl;
  final String? textValue;
  final Map<String, dynamic>? metadata;
  final String? adminNote;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
  final bool canEdit;

  const VerificationDocumentModel({
    required this.type,
    required this.label,
    required this.status,
    this.fileUrl,
    this.textValue,
    this.metadata,
    this.adminNote,
    this.uploadedAt,
    this.verifiedAt,
    this.canEdit = true,
  });

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    final type = VerificationDocType.fromApi(json['type'] as String);
    return VerificationDocumentModel(
      type: type ?? VerificationDocType.profilePhoto,
      label: json['label'] as String? ?? 'Document',
      status: VerificationStatus.fromApi(json['status'] as String?),
      fileUrl: json['fileUrl'] as String?,
      textValue: json['textValue'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      adminNote: json['adminNote'] as String?,
      uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt'] as String) : null,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
      canEdit: json['canEdit'] as bool? ?? true,
    );
  }

  bool get isLocked => status == VerificationStatus.pending || status == VerificationStatus.verified;
  bool get isVerified => status == VerificationStatus.verified;
  bool get isPending => status == VerificationStatus.pending;
  bool get isRejected => status == VerificationStatus.rejected;

  bool get isSecurityPhoto =>
      type == VerificationDocType.securityPhoto1 ||
      type == VerificationDocType.securityPhoto2 ||
      type == VerificationDocType.securityPhoto3 ||
      type == VerificationDocType.securityPhoto4 ||
      type == VerificationDocType.securityPhoto5;

  bool get needsTextInput =>
      type == VerificationDocType.fullAddress || type == VerificationDocType.bankDetails;
}

class VerificationSummaryModel {
  final int totalRequired;
  final int verifiedCount;
  final int pendingCount;
  final int rejectedCount;
  final int completionPercent;
  final bool fullyVerified;

  const VerificationSummaryModel({
    required this.totalRequired,
    required this.verifiedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.completionPercent,
    required this.fullyVerified,
  });

  factory VerificationSummaryModel.fromJson(Map<String, dynamic> json) => VerificationSummaryModel(
        totalRequired: json['totalRequired'] as int? ?? 11,
        verifiedCount: json['verifiedCount'] as int? ?? 0,
        pendingCount: json['pendingCount'] as int? ?? 0,
        rejectedCount: json['rejectedCount'] as int? ?? 0,
        completionPercent: json['completionPercent'] as int? ?? 0,
        fullyVerified: json['fullyVerified'] as bool? ?? false,
      );
}

class VerificationBundleModel {
  final List<VerificationDocumentModel> documents;
  final VerificationSummaryModel summary;

  const VerificationBundleModel({required this.documents, required this.summary});

  factory VerificationBundleModel.fromJson(Map<String, dynamic> json) {
    final docs = (json['documents'] as List<dynamic>? ?? [])
        .map((e) => VerificationDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return VerificationBundleModel(
      documents: docs,
      summary: VerificationSummaryModel.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }

  VerificationDocumentModel? doc(VerificationDocType type) {
    for (final d in documents) {
      if (d.type == type) return d;
    }
    return null;
  }

  List<VerificationDocumentModel> get securityPhotos =>
      documents.where((d) => d.isSecurityPhoto).toList();

  List<VerificationDocumentModel> get submittedDocuments =>
      documents.where((d) => d.status != VerificationStatus.notSubmitted).toList();
}
