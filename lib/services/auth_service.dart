import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _studentDomain = '@gmail.com';

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  String _toEmail(String identifier) {
    final cleaned = identifier.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.contains('@')) return cleaned;
    return '$cleaned$_studentDomain';
  }

  Future<Session?> signUp({
    required String studentId,
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'student_id': studentId.trim(),
        },
      );

      if (response.session == null) {
        if (response.user != null) return null;
        throw Exception('Sign-up failed. Please try again.');
      }
      return response.session;
    } on AuthException catch (e) {
      throw Exception('Sign-up failed: ${e.message}');
    }
  }

  Future<Session> signIn({
    required String identifier,
    required String password,
  }) async {
    final email = _toEmail(identifier);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw Exception('Sign-in failed: Invalid credentials.');
      }
      return response.session!;
    } on AuthException catch (e) {
      throw Exception('Sign-in failed: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ✅ Sends the reset link with the deep link URL
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.smartschool://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception('Reset failed: ${e.message}');
    }
  }

  Future<ProfileModel> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) throw Exception('Profile not found');
    return ProfileModel.fromJson(response);
  }

  Future<void> updateAvatar(Uint8List bytes, String extension) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    final path = '${user.id}/avatar.$extension';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final urlWithTimestamp =
        '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await _client
        .from('profiles')
        .update({
          'avatar_url': urlWithTimestamp,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }
}
