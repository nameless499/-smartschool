class Payment {
  final String id;
  final String requestId;
  final String studentEmail;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? receiptPath;
  final String status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime paidAt;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.requestId,
    required this.studentEmail,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.receiptPath,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    required this.paidAt,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      studentEmail: json['student_email'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      referenceNumber: json['reference_number'] as String?,
      receiptPath: json['receipt_path'] as String?,
      status: json['status'] as String? ?? 'Pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'student_email': studentEmail,
    'amount': amount,
    'payment_method': paymentMethod,
    'reference_number': referenceNumber,
    'receipt_path': receiptPath,
    'status': status,
    'notes': notes,
    'updated_at': DateTime.now().toIso8601String(),
  };

  bool get isVerified => status == 'Verified';
  bool get isPending => status == 'Pending';
  bool get isRejected => status == 'Rejected';
}

class PaymentSummary {
  final double totalAmount;
  final double totalVerified;
  final double totalPending;
  final double balance;

  PaymentSummary({
    required this.totalAmount,
    required this.totalVerified,
    required this.totalPending,
    required this.balance,
  });

  factory PaymentSummary.empty() => PaymentSummary(
    totalAmount: 0,
    totalVerified: 0,
    totalPending: 0,
    balance: 0,
  );

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      totalVerified: (json['total_verified'] as num?)?.toDouble() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
