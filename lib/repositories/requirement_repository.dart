import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_requirement.dart';

class RequirementRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RequestRequirement>> getRequirements(String requestId) async {
    final response = await _client
        .from('request_requirements')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: true);
    return response
        .map<RequestRequirement>((json) => RequestRequirement.fromJson(json))
        .toList();
  }

  // 👇 THE MISSING PIECE — called when a new request is submitted
  Future<void> createRequirementsForRequest({
    required String requestId,
    required String documentTypeId,
  }) async {
    // 1. Fetch the template from document_types
    final docType = await _client
        .from('document_types')
        .select('required_documents')
        .eq('id', documentTypeId)
        .maybeSingle();

    final raw = docType?['required_documents'] as List? ?? [];
    if (raw.isEmpty) return;

    // 2. Build rows — supports plain strings OR objects with is_hardcopy
    final rows = raw.map((item) {
      if (item is String) {
        return {
          'request_id': requestId,
          'requirement_name': item,
          'status': 'Pending',
          'is_required': true,
          'is_hardcopy': false,
        };
      }
      final map = item as Map;
      return {
        'request_id': requestId,
        'requirement_name': map['name'] as String? ?? 'Requirement',
        'status': 'Pending',
        'is_required': (map['is_required'] as bool?) ?? true,
        'is_hardcopy': (map['is_hardcopy'] as bool?) ?? false,
      };
    }).toList();

    // 3. Insert all rows in one batch
    await _client.from('request_requirements').insert(rows);
  }

  Future<void> submitRequirement({
    required String requirementId,
    required String fileUrl,
  }) async {
    await _client
        .from('request_requirements')
        .update({
          'file_url': fileUrl,
          'status': 'Submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requirementId);
  }

  // 👇 NEW: Student marks a hardcopy requirement as physically submitted
  Future<void> markHardcopySubmitted(String requirementId) async {
    await _client
        .from('request_requirements')
        .update({
          'status': 'Submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requirementId);
  }

  Future<void> verifyRequirement(String requirementId) async {
    final userId = _client.auth.currentUser?.id;
    await _client
        .from('request_requirements')
        .update({
          'status': 'Verified',
          'verified_at': DateTime.now().toIso8601String(),
          'verified_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requirementId);
  }

  Future<void> rejectRequirement(String requirementId, String reason) async {
    await _client
        .from('request_requirements')
        .update({
          'status': 'Rejected',
          'rejection_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requirementId);
  }

  Future<bool> allRequirementsVerified(String requestId) async {
    final reqs = await getRequirements(requestId);
    if (reqs.isEmpty) return true;
    return reqs
        .where((r) => r.isRequired && !r.isHardcopy)
        .every((r) => r.isVerified);
  }
}
