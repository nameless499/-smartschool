import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 2. Initialize Local Notifications (Required to show the banner)
  await NotificationService().initialize();

  // 3. Listen for Auth Changes & Password Recovery
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    final session = data.session;

    // 👇 Handle Password Recovery Links
    if (event == AuthChangeEvent.passwordRecovery) {
      debugPrint('🔑 Password recovery link detected! Navigating...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRoutes.router.go(AppRoutes.changePassword);
      });
    }

    // 👇 Handle Notification Subscriptions based on Login State
    if (session != null) {
      // User is logged in -> Start listening for their real-time notifications
      debugPrint('👤 User logged in. Subscribing to notifications...');
      NotificationService().subscribeToRealtime(session.user.id);
    } else {
      // User is logged out -> Stop listening to save resources
      debugPrint('🚪 User logged out. Unsubscribing...');
      NotificationService().unsubscribe();
    }
  });

  // 4. Check if the user is ALREADY logged in when the app starts
  final currentSession = Supabase.instance.client.auth.currentSession;
  if (currentSession != null) {
    NotificationService().subscribeToRealtime(currentSession.user.id);
  }

  runApp(const SmartSchoolApp());
}
