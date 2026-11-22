import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_request.dart';
import '../models/document_type.dart';
import 'requirement_repository.dart';

class DocumentRequestRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // STUDENT METHODS
  // ============================================================

  Future<List<DocumentType>> getDocumentTypes() async {
    final response = await _client
        .from('document_types')
        .select()
        .eq('is_active', true)
        .order('category', ascending: true)
        .order('name', ascending: true);
    return response
        .map<DocumentType>((json) => DocumentType.fromJson(json))
        .toList();
  }

  Future<List<DocumentRequest>> getStudentRequests(String studentEmail) async {
    final response = await _client
        .from('document_requests')
        .select()
        .eq('student_email', studentEmail)
        .order('created_at', ascending: false);
    return response
        .map<DocumentRequest>((json) => DocumentRequest.fromJson(json))
        .toList();
  }

  Future<List<DocumentRequest>> getStudentReleasedDocuments(
    String studentEmail,
  ) async {
    final response = await _client
        .from('document_requests')
        .select()
        .eq('student_email', studentEmail)
        .not('released_file_path', 'is', null)
        .order('released_at', ascending: false);
    return response
        .map<DocumentRequest>((json) => DocumentRequest.fromJson(json))
        .toList();
  }

  Future<DocumentRequest> createRequest(DocumentRequest request) async {
    final response = await _client
        .from('document_requests')
        .insert(request.toJson())
        .select()
        .single();

    final newRequest = DocumentRequest.fromJson(response);
    final newRequestId = newRequest.id;

    if (newRequest.documentTypeId != null) {
      final reqRepo = RequirementRepository();
      await reqRepo.createRequirementsForRequest(
        requestId: newRequestId,
        documentTypeId: newRequest.documentTypeId!,
      );
    }

    return newRequest;
  }

  // ============================================================
  // REGISTRAR METHODS
  // ============================================================

  Future<List<DocumentRequest>> getAllRequests({String? status}) async {
    var query = _client.from('document_requests').select();

    if (status != null && status != 'All') {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return response
        .map<DocumentRequest>((json) => DocumentRequest.fromJson(json))
        .toList();
  }

  Future<DocumentRequest?> getRequestById(String requestId) async {
    final response = await _client
        .from('document_requests')
        .select()
        .eq('id', requestId)
        .maybeSingle();
    if (response == null) return null;
    return DocumentRequest.fromJson(response);
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'Processing') {
      updates['processed_at'] = DateTime.now().toIso8601String();
    }
    if (status == 'Completed') {
      updates['released_at'] = DateTime.now().toIso8601String();
    }

    // 👇 Added .select() to verify the update worked
    final response = await _client
        .from('document_requests')
        .update(updates)
        .eq('id', requestId)
        .select();

    if (response.isEmpty) {
      throw Exception('Update blocked by Supabase. Please check RLS policies.');
    }
  }

  Future<void> verifyPayment(
    String requestId, {
    required bool paid,
    String? reference,
  }) async {
    final updates = <String, dynamic>{
      'payment_status': paid ? 'Paid' : 'Unpaid',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (reference != null) updates['payment_reference'] = reference;

    // 👇 Added .select() to verify the update worked
    final response = await _client
        .from('document_requests')
        .update(updates)
        .eq('id', requestId)
        .select();

    if (response.isEmpty) {
      throw Exception(
        'Payment update blocked by Supabase. Please check RLS policies.',
      );
    }
  }

  Future<void> updateNotes(String requestId, String notes) async {
    await _client
        .from('document_requests')
        .update({
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // ============================================================
  // RELEASED FILE METHODS (E-COPY)
  // ============================================================

  Future<void> attachReleasedFile({
    required String requestId,
    required String filePath,
    required String fileName,
    required int fileSize,
    String? notes,
  }) async {
    await _client
        .from('document_requests')
        .update({
          'released_file_path': filePath,
          'released_file_name': fileName,
          'released_file_size': fileSize,
          'released_notes': notes,
          'status': 'Completed',
          'released_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> removeReleasedFile(String requestId) async {
    await _client
        .from('document_requests')
        .update({
          'released_file_path': null,
          'released_file_name': null,
          'released_file_size': null,
          'released_notes': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // ============================================================
  // UTILITY
  // ============================================================

  static String generateRequestNumber() {
    final now = DateTime.now();
    final prefix = 'REQ-${now.year}${now.month.toString().padLeft(2, '0')}';
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(
      9,
      13,
    );
    return '$prefix-$random';
  }
}
