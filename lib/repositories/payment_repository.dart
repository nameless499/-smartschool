import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all payments for a request.
  Future<List<Payment>> getPaymentsForRequest(String requestId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: false);
    return response.map<Payment>((json) => Payment.fromJson(json)).toList();
  }

  /// Get all payments for the logged-in student.
  Future<List<Payment>> getStudentPayments(String studentEmail) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('student_email', studentEmail)
        .order('created_at', ascending: false);
    return response.map<Payment>((json) => Payment.fromJson(json)).toList();
  }

  /// Get payment summary for a request.
  Future<PaymentSummary> getPaymentSummary(String requestId) async {
    try {
      final response = await _client.rpc(
        'get_payment_summary',
        params: {'p_request_id': requestId},
      );
      if (response == null || (response as List).isEmpty) {
        return PaymentSummary.empty();
      }
      return PaymentSummary.fromJson(
        (response as List).first as Map<String, dynamic>,
      );
    } catch (e) {
      return PaymentSummary.empty();
    }
  }

  /// Create a new payment (student).
  Future<Payment> createPayment({
    required String requestId,
    required String studentEmail,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    String? receiptPath;

    // Upload receipt if provided
    if (receiptBytes != null && receiptFileName != null) {
      final safeName = receiptFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      receiptPath =
          '$requestId/${DateTime.now().millisecondsSinceEpoch}-$safeName';

      await _client.storage
          .from('payment_receipts')
          .uploadBinary(
            receiptPath,
            receiptBytes,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    final response = await _client
        .from('payments')
        .insert({
          'request_id': requestId,
          'student_email': studentEmail,
          'amount': amount,
          'payment_method': paymentMethod,
          'reference_number': referenceNumber,
          'receipt_path': receiptPath,
          'notes': notes,
          'status': 'Pending',
        })
        .select()
        .single();

    return Payment.fromJson(response);
  }

  /// Registrar verifies a payment.
  Future<void> verifyPayment(String paymentId) async {
    final userId = _client.auth.currentUser?.id;
    await _client
        .from('payments')
        .update({
          'status': 'Verified',
          'verified_by': userId,
          'verified_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId);
  }

  /// Registrar rejects a payment.
  Future<void> rejectPayment(String paymentId, String reason) async {
    await _client
        .from('payments')
        .update({
          'status': 'Rejected',
          'rejection_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId);
  }
}
