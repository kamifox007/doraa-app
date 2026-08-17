import 'package:flutter/material.dart';
import 'package:doraa/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doraa/core/widgets/glass_container.dart';
import 'package:doraa/services/notification_db_service.dart';
import 'package:doraa/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    final notificationDb = ref.watch(notificationDbServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(tr('notifications_setting'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<NotificationModel>>(
          future: notificationDb.fetchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل الإشعارات', style: const TextStyle(color: Colors.red)));
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade800),
                    const SizedBox(height: 16),
                    Text(tr('no_new_notifications'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
                // Determine icon based on type
                IconData icon;
                Color iconColor = const Color(0xFFFFD700);
                if (notif.type == 'SYSTEM') icon = Icons.info_outline;
                else if (notif.type == 'PROMO') icon = Icons.local_offer;
                else icon = Icons.notifications;

                return GestureDetector(
                  onTap: () {
                    if (!notif.isRead) {
                      notificationDb.markAsRead(notif.id);
                    }
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    opacity: notif.isRead ? 0.05 : 0.15, // Unread notifications are slightly brighter
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.1),
                          child: Icon(icon, color: iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold, color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(notif.body, style: TextStyle(color: Colors.white.withValues(alpha: notif.isRead ? 0.5 : 0.9))),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(notif.createdAt), 
                                style: const TextStyle(fontSize: 12, color: Color(0xFFFFD700), fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

