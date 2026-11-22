import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications/notification_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at'),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          final notifications = snapshot.data!;
          unreadCount = notifications
              .where((n) => n['is_read'] == false)
              .length;
        }

        return IconButton(
          icon: Badge(
            label: Text(unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            backgroundColor: Colors.redAccent,
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Notifications',
              barrierColor: Colors.black.withOpacity(0.4),
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (context, animation, secondaryAnimation) {
                return const NotificationScreen();
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        );
                    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeIn,
                          ),
                        );
                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        alignment: Alignment.topRight,
                        child: child,
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }
}
