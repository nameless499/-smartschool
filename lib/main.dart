import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('STARTUP 1: Flutter initialized');

  try {
    debugPrint('STARTUP 2: Initializing Supabase');

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ).timeout(const Duration(seconds: 20));

    debugPrint('STARTUP 3: Supabase initialized');
  } catch (e, stackTrace) {
    debugPrint('SUPABASE ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    debugPrint('STARTUP 4: Initializing notifications');

    await NotificationService().initialize().timeout(
      const Duration(seconds: 10),
    );

    debugPrint('STARTUP 5: Notifications initialized');
  } catch (e, stackTrace) {
    debugPrint('NOTIFICATION ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;

    if (data.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRoutes.router.go(AppRoutes.changePassword);
      });
    }

    if (session != null) {
      NotificationService().subscribeToRealtime(session.user.id);
    } else {
      NotificationService().unsubscribe();
    }
  });

  final currentSession = Supabase.instance.client.auth.currentSession;

  if (currentSession != null) {
    NotificationService().subscribeToRealtime(currentSession.user.id);
  }

  debugPrint('STARTUP 6: Calling runApp');

  runApp(const SmartSchoolApp());
}
