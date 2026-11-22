class DocumentRequest {
  final String id;
  final String requestNumber;
  final String? studentId;
  final String studentName;
  final String? studentEmail;
  final String? documentTypeId;
  final String documentName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? purpose;
  final String status;
  final String paymentStatus;
  final String? paymentReference;
  final String? processedBy;
  final DateTime? processedAt;
  final DateTime? releasedAt;
  final String? verificationCode;
  final String? qrCode;
  final String? notes;
  final String? releasedFilePath;
  final String? releasedFileName;
  final int? releasedFileSize;
  final String? releasedNotes;

  // 👇 NEW: Requirements fields
  final bool requirementsPassed;
  final DateTime? requirementsSubmittedAt;
  final List<String> requirementFiles;

  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentRequest({
    required this.id,
    required this.requestNumber,
    this.studentId,
    required this.studentName,
    this.studentEmail,
    this.documentTypeId,
    required this.documentName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.purpose,
    required this.status,
    required this.paymentStatus,
    this.paymentReference,
    this.processedBy,
    this.processedAt,
    this.releasedAt,
    this.verificationCode,
    this.qrCode,
    this.notes,
    this.releasedFilePath,
    this.releasedFileName,
    this.releasedFileSize,
    this.releasedNotes,

    // 👇 NEW: Requirements fields
    this.requirementsPassed = false,
    this.requirementsSubmittedAt,
    this.requirementFiles = const [],

    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentRequest.fromJson(Map<String, dynamic> json) {
    return DocumentRequest(
      id: json['id'] as String,
      requestNumber: json['request_number'] as String,
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String,
      studentEmail: json['student_email'] as String?,
      documentTypeId: json['document_type_id'] as String?,
      documentName: json['document_name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] as String?,
      status: json['status'] as String? ?? 'Pending',
      paymentStatus: json['payment_status'] as String? ?? 'Unpaid',
      paymentReference: json['payment_reference'] as String?,
      processedBy: json['processed_by'] as String?,
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      releasedAt: json['released_at'] != null
          ? DateTime.parse(json['released_at'] as String)
          : null,
      verificationCode: json['verification_code'] as String?,
      qrCode: json['qr_code'] as String?,
      notes: json['notes'] as String?,
      releasedFilePath: json['released_file_path'] as String?,
      releasedFileName: json['released_file_name'] as String?,
      releasedFileSize: json['released_file_size'] as int?,
      releasedNotes: json['released_notes'] as String?,

      // 👇 NEW: Parse requirements fields from JSON
      requirementsPassed: json['requirements_passed'] as bool? ?? false,
      requirementsSubmittedAt: json['requirements_submitted_at'] != null
          ? DateTime.parse(json['requirements_submitted_at'] as String)
          : null,
      requirementFiles: json['requirement_files'] != null
          ? List<String>.from(json['requirement_files'] as List)
          : const [],

      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_number': requestNumber,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'document_type_id': documentTypeId,
      'document_name': documentName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'purpose': purpose,
      'status': status,
      'payment_status': paymentStatus,
      'payment_reference': paymentReference,

      // 👇 NEW: Include requirements fields in payload
      'requirements_passed': requirementsPassed,
      'requirements_submitted_at': requirementsSubmittedAt?.toIso8601String(),
      'requirement_files': requirementFiles,

      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get hasReleasedFile =>
      releasedFilePath != null && releasedFilePath!.isNotEmpty;

  // 👇 NEW: Convenience getters for requirements
  bool get hasRequirements => requirementFiles.isNotEmpty;
  int get requirementCount => requirementFiles.length;
}
