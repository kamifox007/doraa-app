import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride_models.dart';
import 'notification_service.dart';

class RideService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase from Dart environment defines if provided.
  /// Use: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  static Future<void> initializeFromEnv() async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envUrl.isNotEmpty && envKey.isNotEmpty) {
      try {
        await Supabase.initialize(url: envUrl, publishableKey: envKey);
      } catch (_) {
        // ignore initialization errors here; app may initialize elsewhere
      }
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'searching':
        return 'البحث عن سائق';
      case 'negotiating':
        return 'المفاوضة';
      case 'accepted':
        return 'تمت الموافقة';
      case 'declined':
        return 'تم الرفض';
      default:
        return 'قيد الإرسال';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // نظام تسعير ذكي - مماثل لـ Yassir / Heetch / InDrive
  // ═══════════════════════════════════════════════════════════════
  // المعادلة: أجرة = رسوم_أساس + (كم × سعر_الكم) + (دقيقة × سعر_الدقيقة)
  // مضروبة في معامل الذروة (Surge) ثم مطروح منها عمولة DORA 10%
  // ═══════════════════════════════════════════════════════════════

  static const double _commissionRate = 0.10; // 10% عمولة DORA

  // ── تعريفات النهار (06:00 - 22:00) ──
  static const double _dayBase        = 200.0;  // رسوم الانطلاق
  static const double _dayPerKm       = 45.0;   // سعر الكيلومتر
  static const double _dayPerMinute   = 3.0;    // سعر الدقيقة

  // ── تعريفات الليل (22:00 - 06:00) ──
  static const double _nightBase      = 250.0;
  static const double _nightPerKm     = 60.0;
  static const double _nightPerMinute = 4.0;

  // ── حد أدنى للأجرة ──
  static const double _minimumFare    = 200.0;

  // ── رسوم الإلغاء والانتظار ──
  static const double waitingFeePerMinute = 15.0; // 15 دج لكل دقيقة تأخير
  static const int freeWaitingMinutes = 5; // 5 دقائق مجانية للزبونة
  static const double baseCancellationFee = 100.0; // 100 دج رسوم إلغاء أساسية

  static double calculateWaitingFee(int waitedMinutes) {
    if (waitedMinutes <= freeWaitingMinutes) return 0.0;
    return (waitedMinutes - freeWaitingMinutes) * waitingFeePerMinute;
  }

  static double calculateCancellationFee(double driverDistanceFromPickupKm, int minutesElapsed) {
    if (minutesElapsed < 2) return 0.0; // مجاني أول دقيقتين
    double fee = baseCancellationFee;
    if (driverDistanceFromPickupKm < 1.0) {
       fee += 50.0; // غرامة أكبر إذا كانت السائقة قريبة جداً
    }
    return fee;
  }

  static Future<void> applyCancellationPenalty({
    required String userId,
    required double feeAmount,
    required String rideId,
  }) async {
    try {
      await client.from('cancellation_fees').insert({
        'user_id': userId,
        'ride_id': rideId,
        'fee_amount': feeAmount,
        'status': 'unpaid',
      });
    } catch (_) {
      // Ignore
    }
  }

  /// هل الوقت الحالي ليلي؟
  static bool isNightTime([DateTime? at]) {
    final hour = (at ?? DateTime.now()).hour;
    return hour >= 22 || hour < 6;
  }

  /// حساب معامل الذروة (Surge Pricing)
  /// يُرفع السعر تلقائياً خلال ساعات الذروة أو الطلب العالي
  static double surgeMultiplier({int activeRiders = 0, int availableDrivers = 1, DateTime? at}) {
    final hour = (at ?? DateTime.now()).hour;

    // ذروة الصباح: 07:00 - 09:00
    final isMorningPeak = hour >= 7 && hour <= 9;
    // ذروة المساء: 17:00 - 20:00
    final isEveningPeak = hour >= 17 && hour <= 20;

    // نسبة الطلب إلى العرض
    final demandRatio = availableDrivers > 0 ? activeRiders / availableDrivers : 1.0;

    double surge = 1.0;
    if (isMorningPeak || isEveningPeak) surge += 0.2; // +20% في الذروة
    if (demandRatio > 2.0) surge += 0.3;              // +30% إذا الطلب ضعف العرض
    if (isNightTime(at)) surge += 0.1;               // +10% ليلاً (زيادة على السعر الليلي)

    return surge.clamp(1.0, 2.5); // الحد الأقصى 2.5x
  }

  /// حساب أجرة الرحلة الكاملة مع جميع العوامل
  static FareBreakdown calculateSuggestedFareDetailed({
    required double distanceKm,
    required int durationMinutes,
    int activeRiders = 0,
    int availableDrivers = 1,
    DateTime? at,
  }) {
    final night = isNightTime(at);
    final surge = surgeMultiplier(
      activeRiders: activeRiders,
      availableDrivers: availableDrivers,
      at: at,
    );

    final base     = night ? _nightBase      : _dayBase;
    final perKm    = night ? _nightPerKm     : _dayPerKm;
    final perMin   = night ? _nightPerMinute : _dayPerMinute;

    final rawFare  = base + (distanceKm * perKm) + (durationMinutes * perMin);
    final afterSurge = rawFare * surge;
    final totalFare  = afterSurge.clamp(_minimumFare, double.infinity);

    final commission = totalFare * _commissionRate;
    final driverNet  = totalFare - commission;

    return FareBreakdown(
      baseFare: base,
      distanceFare: distanceKm * perKm,
      timeFare: durationMinutes * perMin,
      surgeMultiplier: surge,
      totalFare: double.parse(totalFare.toStringAsFixed(0)),
      commission: double.parse(commission.toStringAsFixed(0)),
      driverNet: double.parse(driverNet.toStringAsFixed(0)),
      isNight: night,
    );
  }

  /// دالة مختصرة للتوافق مع الكود القديم
  static double calculateSuggestedFare({
    required double distanceKm,
    required int durationMinutes,
    DateTime? at,
  }) {
    return calculateSuggestedFareDetailed(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      at: at,
    ).totalFare;
  }

  // ═══════════════════════════════════════════════════════════════
  // نظام الاشتراك - الشهر الأول مجاناً
  // ═══════════════════════════════════════════════════════════════
  static const double monthlySubscriptionFee = 3000.0; // 3000 دج/شهر

  /// هل السائقة في الشهر المجاني؟
  static bool isInFreeTrial(DateTime registrationDate) {
    final now = DateTime.now();
    final diff = now.difference(registrationDate).inDays;
    return diff <= 30; // أول 30 يوم مجاناً
  }

  /// هل تمت الاشتراك الشهري للسائقة؟
  static bool isSubscriptionActive({
    required DateTime? subscriptionExpiry,
    required DateTime registrationDate,
  }) {
    if (isInFreeTrial(registrationDate)) return true; // مجاني
    if (subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(subscriptionExpiry);
  }

  static String buildShareRideMessage({
    required String riderName,
    required String driverName,
    required String carInfo,
    required String plateNumber,
    required String driverPhone,
    required String pickup,
    required String dropoff,
    required int etaMinutes,
    required String rideId,
  }) {
    return '''🚗 رحلة $riderName

السائقة: $driverName ✅ موثقة
السيارة: $carInfo
اللوحة: $plateNumber
رقم الهاتف: $driverPhone

📍 موقع الانطلاق: $pickup
📍 الوجهة: $dropoff

⏱️ وقت الوصول: $etaMinutes دقائق
🔗 تتبع مباشر: https://app.com/live/$rideId''';
  }

  static String buildAutoShareMessage({
    required String riderName,
    required String driverName,
    required String pickup,
    required String dropoff,
    required String rideId,
    required int price,
  }) {
    return '''🚗 رحلة جديدة - $driverName

الزبونة: $riderName ✅ موثقة

📍 موقع الانطلاق: $pickup
📍 الوجهة: $dropoff
⏰ وقت البدء: الآن
💰 السعر: $price دينار

🔗 تتبع مباشر: https://app.com/live/$rideId''';
  }

  static String emergencyMenuText() {
    return '📞 اتصال بأقرب شخص\n📞 اتصال بالشرطة 1548\n🎙️ بدء التسجيل';
  }

  static String buildProfileStatusLabel({
    required bool isOnline,
    required bool notificationsEnabled,
  }) {
    final status = isOnline ? 'متصلة الآن' : 'غير متصلة';
    final notifications = notificationsEnabled ? 'الإشعارات مفعلة' : 'الإشعارات متوقفة';
    return '$status • $notifications';
  }

  static String buildSafetyHandoffMessage({
    required String riderName,
    required String driverName,
    required String pickup,
    required String dropoff,
    required String rideId,
    required int price,
    required String vehicleInfo,
    required String plateNumber,
  }) {
    return '''🚗 رحلة جديدة - $driverName

الزبونة: $riderName ✅ موثقة
السيارة: $vehicleInfo
اللوحة: $plateNumber

📍 موقع الانطلاق: $pickup
📍 الوجهة: $dropoff
⏰ وقت البدء: الآن
💰 السعر: $price دينار

🔗 تتبع مباشر: https://app.com/live/$rideId''';
  }

  static Future<void> triggerSOS({
    required String rideId,
    required String userId,
    required String role,
    required double lat,
    required double lng,
  }) async {
    try {
      await client.from('sos_alerts').insert({
        'ride_id': rideId,
        'user_id': userId,
        'role': role,
        'latitude': lat,
        'longitude': lng,
        'status': 'active',
      });
      debugPrint('🚨 SOS TRIGGERED 🚨');
    } catch (_) {
      // Ignore
    }
  }

  static String generateLiveTrackingLink(String rideId) {
    return 'https://app.dora.com/live/$rideId';
  }

  static double calculateCommission(double fare, {double commissionRate = 0.15}) {
    return double.parse((fare * commissionRate).toStringAsFixed(2));
  }

  static double calculateNetEarnings(double fare, {double commissionRate = 0.15}) {
    return double.parse((fare - (fare * commissionRate)).toStringAsFixed(2));
  }

  static String buildReceiptSummary({
    required String riderName,
    required String driverName,
    required String pickup,
    required String dropoff,
    required double fare,
    required String date,
  }) {
    return '''إيصال رحلة
الزبون: $riderName
السائق: $driverName
من: $pickup
إلى: $dropoff
التاريخ: $date
الإجمالي: ${fare.toInt()} دج''';
  }

  static Map<String, double> buildEarningsSummary(double fare) {
    final commission = calculateCommission(fare);
    final net = calculateNetEarnings(fare);
    return {
      'gross': fare,
      'today': fare,
      'week': fare * 3,
      'month': fare * 10,
      'commission': commission,
      'net': net,
    };
  }

  Future<void> createRatingRecord({
    required String rideId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
    required bool isDriverRating,
  }) async {
    try {
      await client.from('ratings').insert({
        'ride_id': rideId,
        'reviewer_id': reviewerId,
        'reviewed_id': revieweeId,
        'rating': rating,
        'comment': comment,
        'is_driver_rating': isDriverRating,
      });
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  Future<void> createCommissionRecord({
    required String rideId,
    required double fare,
    required String driverId,
    double commissionRate = 0.15,
  }) async {
    final commission = calculateCommission(fare, commissionRate: commissionRate);
    final net = calculateNetEarnings(fare, commissionRate: commissionRate);
    try {
      await client.from('commissions').insert({
        'ride_id': rideId,
        'driver_id': driverId,
        'fare': fare,
        'commission_rate': commissionRate,
        'commission_amount': commission,
        'net_earnings': net,
        'status': 'pending',
      });
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  Future<void> updateProfileTotals({
    required String userId,
    required String role,
    required int completedRides,
    double? averageRating,
  }) async {
    try {
      final table = role == 'driver' ? 'driver_profiles' : 'rider_profiles';
      final updateData = <String, dynamic>{
        'total_rides': completedRides,
      };
      if (averageRating != null) {
        updateData['average_rating'] = averageRating;
      }
      await client.from(table).upsert({
        'user_id': userId,
        ...updateData,
      });
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  static double minFareForEstimate(double fare) {
    return double.parse((fare * 0.8).toStringAsFixed(1));
  }

  static double maxFareForEstimate(double fare) {
    return double.parse((fare * 1.2).toStringAsFixed(1));
  }

  Future<Map<String, String>> createRide({
    required String riderId,
    required String pickup,
    required String dropoff,
    required double proposedFare,
  }) async {
    final pin = (1000 + Random().nextInt(9000)).toString();
    final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final response = await client.from('rides').insert({
        'rider_id': riderId,
        'pickup_address': pickup,
        'dropoff_address': dropoff,
        'proposed_fare': proposedFare,
        'status': 'searching',
        'ride_pin': pin,
        'negotiation_history': [],
      }).select('id') as List<dynamic>?;

      if (response != null && response.isNotEmpty) {
        final first = response.first as Map<String, dynamic>?;
        if (first != null && first['id'] != null) {
          return {'id': first['id'].toString(), 'pin': pin};
        }
      }
    } catch (_) {
      // Fallback to local-only flow when Supabase config is unavailable.
    }
    return {'id': fallbackId, 'pin': pin};
  }

  Future<String?> uploadVoiceNote(dynamic audioFile, String rideId) async {
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '$rideId/$fileName';
      await client.storage.from('voice_notes').upload(path, audioFile);
      return client.storage.from('voice_notes').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String content,
    required String type,
  }) async {
    try {
      await client.from('ride_messages').insert({
        'ride_id': rideId,
        'sender_id': senderId,
        'content': content,
        'message_type': type,
      });
    } catch (_) {
      // ignore
    }
  }

  Stream<List<RideMessage>> subscribeToMessages(String rideId) {
    try {
      return client.from('ride_messages').stream(primaryKey: ['id']).eq('ride_id', rideId).order('created_at').map((data) {
        return data.map((e) => RideMessage(
          id: e['id'].toString(),
          rideId: e['ride_id'].toString(),
          senderId: e['sender_id'].toString(),
          content: e['content'].toString(),
          type: e['message_type'].toString(),
          createdAt: DateTime.parse(e['created_at'].toString()),
        )).toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<void> updateRideStatus({required String rideId, required String status}) async {
    try {
      await client.from('rides').update({'status': status}).eq('id', rideId);
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  Future<void> updateNegotiationHistory({
    required String rideId,
    required List<Map<String, dynamic>> history,
    required String lastMessage,
  }) async {
    try {
      await client.from('rides').update({'negotiation_history': history, 'last_message': lastMessage}).eq('id', rideId);
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  Future<void> insertLocationUpdate({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await client.from('ride_locations').insert({
        'ride_id': rideId,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {
      // Ignore offline/local fallback.
    }
  }

  /// 🌟 خوارزمية التحقق الجغرافي المشترك (Co-location) لبدء الرحلة تلقائياً
  /// تعيد true إذا كانت المسافة بين الهاتفين أقل من [maxDistanceMeters]
  /// وكلاهما يتحرك بسرعة أعلى من [minSpeedKmH].
  static bool checkAutoStartCondition({
    required double riderLat,
    required double riderLng,
    required double driverLat,
    required double driverLng,
    required double currentSpeedKmH,
    double maxDistanceMeters = 15.0,
    double minSpeedKmH = 5.0,
  }) {
    // 1. حساب المسافة بدقة بين الراكبة والسائقة
    final distance = Geolocator.distanceBetween(
      riderLat, riderLng,
      driverLat, driverLng,
    );

    // 2. التحقق من الشروط (مسافة قريبة جداً + سيارة تتحرك)
    if (distance <= maxDistanceMeters && currentSpeedKmH >= minSpeedKmH) {
      return true;
    }
    return false;
  }

  /// 🌟 خوارزمية التطابق الجغرافي للرحلات التشاركية (Shared Rides Matching)
  /// تتحقق رياضياً في الخلفية (Backend Algorithm Mock) ما إذا كانت الوجهتان في طريق متقارب
  /// تعتمد على حساب نسبة الانحراف (Detour Ratio) لضمان عدم إزعاج السائقة أو الراكبة الأولى.
  static bool checkSharedRideMatch({
    required double r1PickupLat, required double r1PickupLng,
    required double r1DropoffLat, required double r1DropoffLng,
    required double r2PickupLat, required double r2PickupLng,
    required double r2DropoffLat, required double r2DropoffLng,
    double maxDetourRatio = 1.25, // أقصى انحراف مسموح به هو 25% زيادة عن مسار الرحلة الأولى
    double maxPickupDistanceMeters = 2000.0, // يجب أن تكون الراكبة الثانية في دائرة 2 كم من نقطة الركوب
  }) {
    // 1. المسافة الأصلية للراكبة الأولى (الخط المباشر)
    final originalDistance = Geolocator.distanceBetween(
      r1PickupLat, r1PickupLng,
      r1DropoffLat, r1DropoffLng,
    );

    // 2. المسافة بين نقطتي الركوب
    final pickupDistance = Geolocator.distanceBetween(
      r1PickupLat, r1PickupLng,
      r2PickupLat, r2PickupLng,
    );

    // نرفض الدمج فوراً إذا كانت الراكبة الثانية بعيدة جداً عن نقطة الانطلاق
    if (pickupDistance > maxPickupDistanceMeters) return false;

    // 3. حساب مسار الرحلة المشتركة المقترح:
    // المسار: (ركوب 1) -> (ركوب 2) -> (نزول 2) -> (نزول 1)
    final d1 = pickupDistance;
    final d2 = Geolocator.distanceBetween(
      r2PickupLat, r2PickupLng,
      r2DropoffLat, r2DropoffLng,
    );
    final d3 = Geolocator.distanceBetween(
      r2DropoffLat, r2DropoffLng,
      r1DropoffLat, r1DropoffLng,
    );

    final sharedDistance = d1 + d2 + d3;

    // 4. تقييم الانحراف
    // إذا كانت المسافة الإجمالية الجديدة لا تتعدى المسافة الأصلية بـ 25%، فالطريق متقارب ومثالي!
    if (originalDistance > 0 && (sharedDistance / originalDistance) <= maxDetourRatio) {
      return true; // التطابق ناجح
    }

    return false; // التطابق فاشل، الوجهات متعاكسة أو تسبب انحرافاً كبيراً
  }


  Future<List<RideOffer>> nearbyDrivers() async {
    return const [
      RideOffer(id: 'd1', name: 'سارة', rating: 4.9, carInfo: 'تويوتا كورولا', distanceKm: 2.1, etaMinutes: 4),
      RideOffer(id: 'd2', name: 'ريم', rating: 4.8, carInfo: 'هيونداي إلنترا', distanceKm: 3.4, etaMinutes: 7),
      RideOffer(id: 'd3', name: 'نوف', rating: 4.7, carInfo: 'كيا سيراتو', distanceKm: 4.9, etaMinutes: 9),
    ];
  }

  Stream<List<Map<String, dynamic>>> subscribeToRide(String riderId) {
    try {
      return client.from('rides').stream(primaryKey: ['id']).eq('rider_id', riderId);
    } catch (_) {
      return Stream.value(const []);
    }
  }

  Stream<Map<String, dynamic>?> subscribeToRideLocation(String rideId) {
    try {
      return client
          .from('ride_locations')
          .stream(primaryKey: ['id'])
          .eq('ride_id', rideId)
          .order('created_at', ascending: false)
          .map((data) => data.isNotEmpty ? data.first : null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToNearbyRequests({required double lat, required double lon}) {
    try {
      return client.from('rides').stream(primaryKey: ['id']).eq('status', 'searching');
    } catch (_) {
      return Stream.value(const []);
    }
  }

  RealtimeChannel? _notificationChannel;

  void startNotificationListener(String userId, String role) {
    _notificationChannel?.unsubscribe();
    
    _notificationChannel = client.channel('public:rides_notifications').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'rides',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord.isEmpty) return;

        if (role == 'driver' && payload.eventType == PostgresChangeEvent.insert) {
          if (newRecord['status'] == 'searching') {
            NotificationService().showNotification(
              id: newRecord['id'].hashCode,
              title: 'طلب رحلة جديد! 🚗',
              body: 'من: ${newRecord['pickup_address']} إلى ${newRecord['dropoff_address']}',
            );
          }
        } 
        else if (role == 'rider' && payload.eventType == PostgresChangeEvent.update) {
          if (newRecord['rider_id'] == userId) {
            final status = newRecord['status'];
            final oldStatus = payload.oldRecord['status'];
            if (status == 'accepted' && oldStatus != 'accepted') {
              NotificationService().showNotification(
                id: newRecord['id'].hashCode,
                title: 'تم قبول رحلتك! ✅',
                body: 'السائقة في طريقها إليك الآن',
              );
            }
          }
        }
      },
    ).subscribe();
  }
}
