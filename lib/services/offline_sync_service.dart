import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  static const String _offlineLocationsKey = 'offline_locations';
  final SupabaseClient _client = Supabase.instance.client;

  /// حفظ إحداثيات السائقة محلياً عند انقطاع الإنترنت
  Future<void> saveLocationLocally(String rideId, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_offlineLocationsKey) ?? [];

    final newLocation = {
      'ride_id': rideId,
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    };

    saved.add(jsonEncode(newLocation));
    await prefs.setStringList(_offlineLocationsKey, saved);
  }

  /// محاولة إرسال البيانات المحفوظة عند عودة الاتصال
  Future<void> syncOfflineData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) &&
        connectivityResult.length == 1) {
      return; // لا يوجد إنترنت
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_offlineLocationsKey) ?? [];
    if (saved.isEmpty) return;

    final List<String> failedToSync = [];

    for (final locString in saved) {
      try {
        final loc = jsonDecode(locString) as Map<String, dynamic>;
        await _client.from('ride_locations').insert({
          'ride_id': loc['ride_id'],
          'latitude': loc['latitude'],
          'longitude': loc['longitude'],
        });
      } catch (_) {
        // فشل في إرسال هذه النقطة، نحتفظ بها للمحاولة لاحقاً
        failedToSync.add(locString);
      }
    }

    // تحديث القائمة المحلية بالنقاط التي فشلنا في رفعها فقط
    if (failedToSync.isEmpty) {
      await prefs.remove(_offlineLocationsKey);
    } else {
      await prefs.setStringList(_offlineLocationsKey, failedToSync);
    }
  }
}
