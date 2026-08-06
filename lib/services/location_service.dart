import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'ride_service.dart';

class LocationTrackingService {
  StreamSubscription<Position>? _subscription;

  Future<void> startTracking({
    required String rideId,
    required Function(Position position) onLocationUpdate,
  }) async {
    if (_subscription != null) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return;
    }

    DateTime? lastDbUpdateTime;

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // أقصى دقة ممكنة
        distanceFilter: 1, // التحديث على الشاشة عند التحرك متر واحد فقط
      ),
    ).listen((position) async {
      // 1. تحديث الخريطة فوراً كل متر واحد للمستخدم
      onLocationUpdate(position);

      // 2. إرسال البيانات لقاعدة البيانات كل 5 ثوانٍ فقط لتجنب الضغط واستهلاك الإنترنت
      final now = DateTime.now();
      if (lastDbUpdateTime == null || now.difference(lastDbUpdateTime!).inSeconds >= 5) {
        lastDbUpdateTime = now;
        await RideService().insertLocationUpdate(
          rideId: rideId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    });
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
