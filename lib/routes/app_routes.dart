import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // 👈 Imported for XFile
import '../providers/auth_provider.dart';

import '../models/document_request.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/student_profile.dart';
import '../screens/student/verify_student_id_screen.dart';
import '../screens/registrar/registrar_dashboard.dart';
import '../screens/registrar/student_records_screen.dart';
import '../screens/registrar/document_processing_screen.dart';
import '../screens/registrar/student_detail_screen.dart';
import '../screens/registrar/verify_staff_screen.dart';
import '../screens/registrar/request_detail_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/chatbot_knowledge_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/scanner/scan_preview_screen.dart';
import '../screens/scanner/extracted_data_screen.dart';
import '../screens/requests/document_request_screen.dart';
import '../screens/requests/request_status_screen.dart';
import '../screens/payments/payment_screen.dart';
import '../screens/documents/released_documents_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';

  static const String profile = '/profile';

  static const String studentDashboard = '/student';
  static const String studentProfile = '/student/profile';
  static const String verifyStudentId = '/student/verify';
  static const String chatbot = '/student/chatbot';
  static const String documentRequest = '/student/request';
  static const String requestStatus = '/student/requests';
  static const String payments = '/student/payments';
  static const String releasedDocs = '/student/released';

  static const String registrarDashboard = '/registrar';
  static const String studentRecords = '/registrar/records';
  static const String documentProcessing = '/registrar/processing';
  static const String studentDetail = '/registrar/student/detail';
  static const String requestDetail = '/registrar/request/detail';

  static const String verifyStaff = '/staff/verify';

  static const String scanner = '/registrar/scanner';
  static const String scannerPreview = '/registrar/scanner/preview';
  static const String scannerExtract = '/registrar/scanner/extract';

  static const String adminDashboard = '/admin';
  static const String userManagement = '/admin/users';
  static const String chatbotKnowledge = '/admin/knowledge';

  static GoRouter router = GoRouter(
    initialLocation: landing,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final role = authProvider.role;
      final path = state.uri.path;

      if (isAuthenticated &&
          authProvider.profile == null &&
          authProvider.isLoading) {
        return null;
      }

      if (!isAuthenticated) {
        final publicPaths = [
          landing,
          login,
          register,
          forgotPassword,
          changePassword,
        ];
        if (!publicPaths.contains(path)) return login;
        return null;
      }

      if (path == landing ||
          path == login ||
          path == register ||
          path == forgotPassword) {
        if (authProvider.profile == null) return null;
        return _defaultRouteForRole(role);
      }

      if (path == changePassword) return null;
      if (path == profile) return null;

      if (role == 'student') {
        final isVerified = authProvider.isVerified;
        if (!isVerified && path != verifyStudentId) return verifyStudentId;
        if (isVerified && path == verifyStudentId) return studentDashboard;
      }

      if (role == 'registrar' || role == 'admin') {
        final isStaffVerified = authProvider.isStaffVerified;
        if (!isStaffVerified && path != verifyStaff) return verifyStaff;
        if (isStaffVerified && path == verifyStaff) {
          return role == 'admin' ? adminDashboard : registrarDashboard;
        }
      }

      if (path.startsWith('/registrar') &&
          role != 'registrar' &&
          role != 'admin') {
        return _defaultRouteForRole(role);
      }

      if (path.startsWith('/admin') && role != 'admin') {
        return _defaultRouteForRole(role);
      }

      return null;
    },
    routes: [
      // PUBLIC
      GoRoute(
        path: landing,
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // STUDENT
      GoRoute(
        path: verifyStudentId,
        name: 'verifyStudentId',
        builder: (context, state) => const VerifyStudentIdScreen(),
      ),
      GoRoute(
        path: studentDashboard,
        name: 'studentDashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: studentProfile,
        name: 'studentProfile',
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: chatbot,
        name: 'chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: documentRequest,
        name: 'documentRequest',
        builder: (context, state) => const DocumentRequestScreen(),
      ),
      GoRoute(
        path: requestStatus,
        name: 'requestStatus',
        builder: (context, state) => const RequestStatusScreen(),
      ),
      GoRoute(
        path: payments,
        name: 'payments',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: releasedDocs,
        name: 'releasedDocs',
        builder: (context, state) => const ReleasedDocumentsScreen(),
      ),

      // STAFF VERIFY
      GoRoute(
        path: verifyStaff,
        name: 'verifyStaff',
        builder: (context, state) => const VerifyStaffScreen(),
      ),

      // REGISTRAR
      GoRoute(
        path: registrarDashboard,
        name: 'registrarDashboard',
        builder: (context, state) => const RegistrarDashboard(),
      ),
      GoRoute(
        path: studentRecords,
        name: 'studentRecords',
        builder: (context, state) => const StudentRecordsScreen(),
      ),
      GoRoute(
        path: documentProcessing,
        name: 'documentProcessing',
        builder: (context, state) => const DocumentProcessingScreen(),
      ),
      GoRoute(
        path: scanner,
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),

      // 👇 THE FIX IS HERE
      GoRoute(
        path: scannerPreview,
        name: 'scannerPreview',
        builder: (context, state) {
          final file = state.extra as XFile?;
          return ScanPreviewScreen(imageFile: file);
        },
      ),
      GoRoute(
        path: scannerExtract,
        name: 'scannerExtract',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return ExtractedDataScreen(data: data);
        },
      ),
      GoRoute(
        path: studentDetail,
        name: 'studentDetail',
        builder: (context, state) {
          final student = state.extra as Map<String, dynamic>?;
          if (student == null)
            return const Scaffold(
              body: Center(child: Text('Student not found')),
            );
          return StudentDetailScreen(student: student);
        },
      ),
      GoRoute(
        path: requestDetail,
        name: 'requestDetail',
        builder: (context, state) {
          final request = state.extra as DocumentRequest?;
          if (request == null)
            return const Scaffold(
              body: Center(child: Text('Request not found')),
            );
          return RequestDetailScreen(request: request);
        },
      ),

      // ADMIN
      GoRoute(
        path: adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: userManagement,
        name: 'userManagement',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: chatbotKnowledge,
        name: 'chatbotKnowledge',
        builder: (context, state) => const ChatbotKnowledgeScreen(),
      ),
    ],
  );

  static String _defaultRouteForRole(String? role) {
    switch (role) {
      case 'student':
        return studentDashboard;
      case 'registrar':
        return registrarDashboard;
      case 'admin':
        return adminDashboard;
      default:
        return login;
    }
  }
}
