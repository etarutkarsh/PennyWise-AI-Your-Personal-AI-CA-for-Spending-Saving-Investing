/// Mirrors com.pennywise.dto.DocumentDto on the backend.
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.documentType,
    required this.ocrStatus,
    required this.verificationStatus,
    required this.createdAt,
    this.originalFilename,
    this.fileUrl,
    this.ocrData,
    this.confidenceScore,
    this.financialYear,
    this.taxCategory,
    this.linkedTransactionId,
  });

  final String id;
  final String documentType;       // FORM_16 | FORM_26AS | AIS | RECEIPT | SALARY_SLIP | INSURANCE | HOME_LOAN | MUTUAL_FUND | PREVIOUS_ITR | OTHER
  final String? originalFilename;
  final String? fileUrl;
  final String ocrStatus;          // PENDING | PROCESSING | COMPLETED | FAILED
  final Map<String, dynamic>? ocrData;
  final double? confidenceScore;
  final String? financialYear;     // e.g. "2025-26"
  final String? taxCategory;
  final String? linkedTransactionId;
  final String verificationStatus; // UNVERIFIED | VERIFIED | DISPUTED
  final DateTime createdAt;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as String,
        documentType: json['documentType'] as String,
        originalFilename: json['originalFilename'] as String?,
        fileUrl: json['fileUrl'] as String?,
        ocrStatus: json['ocrStatus'] as String? ?? 'PENDING',
        ocrData: json['ocrData'] as Map<String, dynamic>?,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
        financialYear: json['financialYear'] as String?,
        taxCategory: json['taxCategory'] as String?,
        linkedTransactionId: json['linkedTransactionId'] as String?,
        verificationStatus: json['verificationStatus'] as String? ?? 'UNVERIFIED',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
