import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart'; // 👈 CRITICAL: Must match your folder
import '../models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Session? _session;
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  bool _isVerified = false;
  bool _staffVerified = false;
  String? _staffPosition;
  Map<String, dynamic>? _verifiedStudent;

  Session? get session => _session;
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _session != null;
  String? get role => _profile?.role;

  bool get isVerified => _isVerified;
  bool get isStaffVerified => _staffVerified;
  String? get staffPosition => _staffPosition;
  Map<String, dynamic>? get verifiedStudent => _verifiedStudent;
  String? get verifiedStudentId => _verifiedStudent?['student_id'] as String?;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _session = _authService.currentSession;
    if (_session != null) {
      await loadProfile();
    }
    _isVerified = false;
    _staffVerified = false;
    _staffPosition = null;
    _verifiedStudent = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    if (_session == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _authService.getCurrentProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String extension) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateAvatar(bytes, extension);
      await loadProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyStaff(String employeeId) async {
    if (_profile == null) {
      _error = 'No profile found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final userRole = _profile!.role ?? '';

      if (userRole != 'registrar' && userRole != 'admin') {
        _error = 'This account is not a staff account.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await supabase.rpc(
        'verify_staff',
        params: {
          'p_employee_id': employeeId.trim().toUpperCase(),
          'p_role': userRole,
        },
      );

      if (response == null || (response as List).isEmpty) {
        _error = 'Employee ID not found.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final staff = (response as List).first as Map<String, dynamic>;
      final staffPosition = staff['job_position'] as String? ?? '';
      final staffEmail = (staff['email'] as String).trim().toLowerCase();
      final myEmail = (_profile!.email).trim().toLowerCase();

      if (staffEmail != myEmail) {
        _error = 'Employee ID does not match your account email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _staffPosition = staffPosition;
      _staffVerified = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Verification failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyStudentId(String studentId) async {
    if (_profile == null) {
      _error = 'No profile found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.rpc(
        'verify_student_id',
        params: {'p_student_id': studentId.trim()},
      );

      if (response == null || (response as List).isEmpty) {
        _error = 'Student ID not found in Medina College records.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final student = (response as List).first as Map<String, dynamic>;
      final enteredName = _profile!.fullName.trim().toLowerCase();
      final recordName = (student['full_name'] as String).trim().toLowerCase();

      final enteredParts = enteredName.split(RegExp(r'\s+'));
      final recordParts = recordName.split(RegExp(r'\s+'));

      final enteredFirst = enteredParts.isNotEmpty ? enteredParts.first : '';
      final enteredLast = enteredParts.length > 1 ? enteredParts.last : '';
      final recordFirst = recordParts.isNotEmpty ? recordParts.first : '';
      final recordLast = recordParts.length > 1 ? recordParts.last : '';

      if (enteredFirst != recordFirst || enteredLast != recordLast) {
        _error =
            'Student ID found but the name does not match.\n'
            'Your name: ${_profile!.fullName}\n'
            'Record on file: ${student['full_name']}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _verifiedStudent = student;
      _isVerified = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Verification failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================
  Future<void> signUp({
    required String studentId,
    required String email,
    required String password,
    required String fullName,
    String role = 'student',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authService.signUp(
        studentId: studentId,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      _isVerified = false;
      _staffVerified = false;
      _verifiedStudent = null;

      if (_session == null) {
        throw Exception('VERIFY_EMAIL');
      }

      await loadProfile();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authService.signIn(
        identifier: identifier,
        password: password,
      );

      _isVerified = false;
      _staffVerified = false;
      _staffPosition = null;
      _verifiedStudent = null;

      await loadProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _session = null;
      _profile = null;
      _isVerified = false;
      _staffVerified = false;
      _staffPosition = null;
      _verifiedStudent = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(identifier);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }
}
