class RideOffer {
  const RideOffer({
    required this.id,
    required this.name,
    required this.rating,
    required this.carInfo,
    required this.distanceKm,
    required this.etaMinutes,
  });

  final String id;
  final String name;
  final double rating;
  final String carInfo;
  final double distanceKm;
  final int etaMinutes;
}

class RideRequest {
  const RideRequest({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.proposedFare,
    required this.status,
    this.pin = '',
    this.isShared = false,
    this.rideType = 'solo',
    this.distanceKm = 0.0,
  });

  final String id;
  final String pickup;
  final String dropoff;
  final double proposedFare;
  final String status;
  final String pin;
  final bool isShared;
  final String rideType;
  final double distanceKm;
}

class RideMessage {
  const RideMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String rideId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;
}

/// تفاصيل تكلفة الرحلة - يُستخدم لعرض تفصيل الأجرة للراكبة والسائقة
class FareBreakdown {
  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.totalFare,
    required this.commission,
    required this.driverNet,
    required this.isNight,
  });

  final double baseFare;          // رسوم الانطلاق
  final double distanceFare;      // تكلفة المسافة
  final double timeFare;          // تكلفة الوقت
  final double surgeMultiplier;   // معامل الذروة
  final double totalFare;         // الإجمالي المدفوع من الراكبة
  final double commission;        // عمولة DORA 10%
  final double driverNet;         // صافي أرباح السائقة
  final bool isNight;             // هل الرحلة ليلية؟

  String get period => isNight ? '🌙 ليلي' : '☀️ نهاري';

  String get surgeLabel {
    if (surgeMultiplier <= 1.0) return '';
    if (surgeMultiplier <= 1.2) return '🔥 ذروة خفيفة';
    if (surgeMultiplier <= 1.5) return '🔥🔥 ذروة متوسطة';
    return '🔥🔥🔥 ذروة عالية';
  }
}
