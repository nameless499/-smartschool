import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getNotifications();
      setState(() => _notifications = data);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTap(NotificationModel notif) async {
    if (!notif.isRead) {
      await _repo.markAsRead(notif.id);
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: Alignment.topRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width > 600 ? 420 : size.width * 0.92,
          height: size.height * 0.88,
          margin: const EdgeInsets.only(
            top: 60,
            right: 12,
            left: 12,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                // ACTION BAR
                if (_notifications.isNotEmpty && !_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            await _repo.markAllAsRead();
                            _loadNotifications();
                          },
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Mark all read'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),

                // LIST
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B5E20),
                          ),
                        )
                      : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications yet.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return InkWell(
                              onTap: () => _handleTap(notif),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: notif.isRead
                                      ? Colors.white
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: notif.isRead
                                        ? Colors.grey.shade200
                                        : Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: notif.isRead
                                          ? Colors.grey.shade200
                                          : Colors.green.shade200,
                                      child: Icon(
                                        notif.type == 'new_request'
                                            ? Icons.request_page_rounded
                                            : notif.type == 'status_update'
                                            ? Icons.update_rounded
                                            : Icons
                                                  .assignment_turned_in_rounded,
                                        size: 20,
                                        color: notif.isRead
                                            ? Colors.grey
                                            : const Color(0xFF1B5E20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            style: GoogleFonts.poppins(
                                              fontWeight: notif.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            notif.message,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                  'MMM d, yyyy • h:mm a',
                                                ).format(
                                                  notif.createdAt.toLocal(),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
