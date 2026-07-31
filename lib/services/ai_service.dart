import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AIService: يحاكي التكامل مع خادم الذكاء الاصطناعي.
/// عند توفر خادم حقيقي، استبدل منطق [_callAIApi] بطلب HTTP حقيقي.
class AIService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Timer? _telemetryTimer;
  static StreamSubscription<Position>? _positionSub;

  // ------------------------------------------------------------------
  // 1. التحقق من هوية السائقة (Face Matching)
  // ------------------------------------------------------------------

  /// يقارن صورة السيلفي مع صورة بطاقة الهوية عبر سيرفر Supabase (Edge Function).
  /// يُعيد نسبة التطابق [0.0 - 1.0] أو null عند الفشل.
  static Future<double?> verifyDriverIdentity({
    required String userId,
    required String selfieUrl,
    required String cniUrl,
  }) async {
    try {
      // استدعاء دالة Edge Function (AWS Rekognition)
      final response = await _client.functions.invoke(
        'verify-identity',
        body: {
          'userId': userId,
          'selfieImageUrl': selfieUrl,
          'cniImageUrl': cniUrl,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        // AWS Rekognition returns similarity as a percentage (e.g. 95.5)
        // We divide by 100 to get a score between 0.0 and 1.0
        final score = (data['similarity'] as num?)?.toDouble() ?? 0.0;
        return score / 100.0;
      } else {
        debugPrint('[AIService] Edge function error: ${response.status} - ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('[AIService] Face match error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // 2. كشف الشذوذ أثناء الرحلة (Anomaly Detection / Telemetry)
  // ------------------------------------------------------------------

  /// يبدأ جمع بيانات الموقع والسرعة كل 30 ثانية وإرسالها.
  static void startAnomalyDetection({
    required String rideId,
    required String driverId,
  }) {
    stopAnomalyDetection(); // أوقف أي جلسة سابقة

    _telemetryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );

        final speedKmH = position.speed * 3.6;
        final bool isSuspicious = speedKmH > 120; // تنبيه: سرعة عالية جداً

        await _saveTelemetry(
          rideId: rideId,
          driverId: driverId,
          lat: position.latitude,
          lng: position.longitude,
          speedKmH: speedKmH,
          isSuspicious: isSuspicious,
        );

        debugPrint('[AI Telemetry Sent] speed=${speedKmH.toStringAsFixed(1)} km/h, suspicious=$isSuspicious');

        if (isSuspicious) {
          await _flagRide(rideId: rideId, reason: 'سرعة مرتفعة جداً: ${speedKmH.toStringAsFixed(0)} كم/س');
        }
      } catch (e) {
        debugPrint('[AIService] Telemetry error: $e');
      }
    });
  }

  /// يوقف جمع بيانات القياس عن بعد.
  static void stopAnomalyDetection() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ------------------------------------------------------------------
  // 3. دوال الحفظ في قاعدة البيانات
  // ------------------------------------------------------------------


  static Future<void> _saveTelemetry({
    required String rideId,
    required String driverId,
    required double lat,
    required double lng,
    required double speedKmH,
    required bool isSuspicious,
  }) async {
    try {
      await _client.from('ride_telemetry').insert({
        'ride_id': rideId,
        'driver_id': driverId,
        'lat': lat,
        'lng': lng,
        'speed_kmh': speedKmH,
        'is_suspicious': isSuspicious,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AIService] Could not save telemetry: $e');
    }
  }

  static Future<void> _flagRide({
    required String rideId,
    required String reason,
  }) async {
    try {
      await _client.from('flagged_rides').upsert({
        'ride_id': rideId,
        'reason': reason,
        'flagged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AIService] Could not flag ride: $e');
    }
  }
}
