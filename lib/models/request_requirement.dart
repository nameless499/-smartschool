class RequestRequirement {
  final String id;
  final String requestId;
  final String requirementName;
  final bool isRequired;
  final bool isHardcopy;
  final String status;
  final String? fileUrl;
  final DateTime? submittedAt;
  final String? notes;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  RequestRequirement({
    required this.id,
    required this.requestId,
    required this.requirementName,
    required this.isRequired,
    required this.isHardcopy,
    required this.status,
    this.fileUrl,
    this.submittedAt,
    this.notes,
    this.rejectionReason,
    this.verifiedAt,
    required this.createdAt,
  });

  factory RequestRequirement.fromJson(Map<String, dynamic> json) {
    return RequestRequirement(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      requirementName: json['requirement_name'] as String,
      isRequired: json['is_required'] as bool? ?? true,
      isHardcopy: json['is_hardcopy'] as bool? ?? false,
      status: json['status'] as String? ?? 'Pending',
      fileUrl: json['file_url'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isSubmitted => status == 'Submitted';
  bool get isVerified => status == 'Verified';
  bool get isRejected => status == 'Rejected';
  bool get isPending => status == 'Pending';
}
