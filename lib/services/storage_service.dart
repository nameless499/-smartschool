import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // REQUIREMENTS
  // ============================================================
  Future<String> uploadRequirement({
    required String requestId,
    required String requirementId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path = '$requestId/$requirementId-$safeName';

    final Uint8List data = bytes is Uint8List
        ? bytes
        : Uint8List.fromList(bytes);

    await _client.storage
        .from('requirements')
        .uploadBinary(path, data, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  Future<List<int>> downloadRequirement(String path) async {
    return await _client.storage.from('requirements').download(path);
  }

  Future<String> getRequirementSignedUrl(String path) async {
    return _client.storage.from('requirements').createSignedUrl(path, 3600);
  }

  // ============================================================
  // RELEASED DOCUMENTS (E-COPY)
  // ============================================================
  Future<String> uploadReleasedDocument({
    required String requestId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$requestId/$timestamp-$safeName';

    final Uint8List data = bytes is Uint8List
        ? bytes
        : Uint8List.fromList(bytes);

    await _client.storage
        .from('released_documents')
        .uploadBinary(path, data, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  Future<List<int>> downloadReleasedDocument(String path) async {
    return await _client.storage.from('released_documents').download(path);
  }

  /// Returns a signed URL for the released document.
  /// The browser will automatically download the file when opened.
  Future<String> getReleasedDocumentSignedUrl(String path) async {
    return _client.storage
        .from('released_documents')
        .createSignedUrl(path, 3600);
  }

  Future<void> deleteReleasedDocument(String path) async {
    await _client.storage.from('released_documents').remove([path]);
  }
}
