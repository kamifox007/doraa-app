import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

// دالة لمعالجة رسائل الخلفية (يجب أن تكون خارج أي كلاس)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // يمكننا وضع كود هنا إذا أردنا التعامل مع بيانات الرسالة في الخلفية
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. طلب الصلاحيات للإشعارات (مهمة للآيفون ولأندرويد 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. إعداد مكتبة الإشعارات المحلية
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, macOS: darwinInit, iOS: darwinInit);
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // يمكن التوجيه إلى شاشة معينة بناءً على الإشعار
        if (details.payload != null) {
          debugPrint('Notification Payload: ${details.payload}');
        }
      },
    );

    // 3. إعداد استقبال الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. إعداد استقبال الإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 5. حفظ وتحديث الـ Token في قاعدة البيانات
    _fcm.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(token);
    });

    // احصل على الـ Token الأول عند التشغيل
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    if (!AppConfig.isSupabaseConfigured) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('user_profiles')
          .update({'fcm_token': token})
          .eq('user_id', userId);
      debugPrint('✅ FCM Token Saved: $token');
    } catch (e) {
      debugPrint('❌ Error saving FCM Token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final androidDetails = message.notification?.android;

    if (notification != null && androidDetails != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'dora_high_importance_channel',
            'إشعارات تطبيق DORA',
            channelDescription: 'يستخدم هذا القناة لإرسال إشعارات الرحلات والطوارئ',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          )
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
