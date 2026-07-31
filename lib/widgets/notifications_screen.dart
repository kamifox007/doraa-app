import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider).tr;
    final notifications = [
      {'title': tr('notif_welcome_title'), 'body': tr('notif_welcome_body'), 'time': tr('two_hours_ago'), 'icon': Icons.celebration, 'color': Colors.pink},
      {'title': tr('notif_driver_active_title'), 'body': tr('notif_driver_active_body'), 'time': tr('five_hours_ago'), 'icon': Icons.check_circle, 'color': Colors.green},
      {'title': tr('notif_discount_title'), 'body': tr('notif_discount_body'), 'time': tr('yesterday'), 'icon': Icons.local_offer, 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notifications_setting'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5F9E)]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(tr('no_new_notifications'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                cacheExtent: 200,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (notif['color'] as Color).withValues(alpha: 0.2),
                      child: Icon(notif['icon'] as IconData, color: notif['color'] as Color),
                    ),
                    title: Text(notif['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['body'] as String),
                        const SizedBox(height: 4),
                        Text(notif['time'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    onTap: () {},
                  );
                },
              ),
      ),
    );
  }
}
