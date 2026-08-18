import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'package:doraa/providers/auth_providers.dart';

final notificationDbServiceProvider = Provider((ref) {
  return NotificationDBService(ref);
});

class NotificationDBService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Ref _ref;

  NotificationDBService(this._ref);

  /// Fetch notifications for the current user
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final authService = _ref.read(authProvider);
      final userId = authService.userId;
      
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    try {
      final authService = _ref.read(authProvider);
      final userId = authService.userId;
      
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Stream for realtime updates (if needed)
  Stream<List<NotificationModel>> streamNotifications() {
    final authService = _ref.read(authProvider);
    final userId = authService.userId;

    if (userId == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => NotificationModel.fromJson(map)).toList());
  }

  /// [Admin Function] Send a global notification to all users
  Future<void> sendGlobalNotification({required String title, required String body, String type = 'SYSTEM'}) async {
    try {
      // Fetch all users
      // In a real production app, this should be a backend Edge Function.
      // Doing this client-side is inefficient for a large userbase.
      final usersResponse = await _supabase.from('profiles').select('id');
      
      final notificationsToInsert = (usersResponse as List).map((user) {
        return {
          'user_id': user['id'],
          'title': title,
          'body': body,
          'type': type,
          'is_read': false,
        };
      }).toList();

      if (notificationsToInsert.isNotEmpty) {
        await _supabase.from('notifications').insert(notificationsToInsert);
      }
    } catch (e) {
      debugPrint('Error sending global notification: $e');
      rethrow;
    }
  }

  /// Send a specific notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'SYSTEM',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
