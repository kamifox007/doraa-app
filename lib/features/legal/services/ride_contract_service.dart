import 'package:crypto/crypto.dart';
import 'dart:convert';

class RideContractService {
  static String generateContract({
    required String rideId,
    required String riderId,
    required String driverId,
    required double agreedFare,
    required String pickupAddress,
    required String dropoffAddress,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contractText = '''
عقد رقمي للرحلة

الرحلة رقم: $rideId
التاريخ: $timestamp

الطرف الأول (الراكبة): $riderId
الطرف الثاني (السائقة): $driverId

تفاصيل الرحلة:
- نقطة الانطلاق: $pickupAddress
- الوجهة: $dropoffAddress
- الأجرة المتفق عليها: $agreedFare د.ج

شروط الرحلة:
1. السائقة مقاولة مستقلة وليست موظفة للتطبيق.
2. الراكبة تلتزم بدفع الأجرة المتفق عليها.
3. إلغاء الرحلة قبل وصول السائقة بـ 5 دقائق يُخضع لغرامة 20%.
4. التطبيق غير مسؤول عن الحوادث المرورية — التأمين على المركبة هو المسؤول.
5. أي نزاع يُحل بالتحكيم أولاً.

بالموافقة على هذه الرحلة، يقر الطرفان بقبول هذه الشروط.
    ''';

    return sha256.convert(utf8.encode(contractText)).toString();
  }
}
