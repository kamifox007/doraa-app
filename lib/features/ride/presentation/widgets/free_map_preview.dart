import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'animated_waiting_rider.dart';

class FreeMapPreview extends StatelessWidget {
  const FreeMapPreview({
    super.key,
    required this.center,
    required this.showPickupMarker,
    this.pickupLocation,
    this.dropoffLocation,
    this.routePolyline,
    this.onCenterChanged,
    this.driverLocation,
    this.waitingRiderLocations = const [],
    this.nearbyDrivers = const [],
    this.isRideStarted = false,
  });

  final LatLng center;
  final bool showPickupMarker;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final List<LatLng>? routePolyline;
  final ValueChanged<LatLng>? onCenterChanged;
  final LatLng? driverLocation;
  final List<LatLng> waitingRiderLocations;
  final List<LatLng> nearbyDrivers;
  final bool isRideStarted;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    
    // 1. عرض الراكبات المنتظرات كأفاتار أنثوي (فقط إذا لم تبدأ الرحلة بعد)
    if (!isRideStarted) {
      if (showPickupMarker || pickupLocation != null) {
        markers.add(
          Marker(
            point: pickupLocation ?? center,
            width: 60,
            height: 60,
            child: const AnimatedWaitingRider(),
          ),
        );
      }
      for (final loc in waitingRiderLocations) {
        markers.add(
          Marker(
            point: loc,
            width: 60,
            height: 60,
            child: const AnimatedWaitingRider(),
          ),
        );
      }
    }

    // 2. عرض الوجهة
    final destination = dropoffLocation;
    if (destination != null) {
      markers.add(
        Marker(
          point: destination,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_pin, color: Color(0xFFFFD700), size: 44),
        ),
      );
    }

    // 3. عرض سيارة السائقة
    if (driverLocation != null) {
      markers.add(
        Marker(
          point: driverLocation!,
          width: 50,
          height: 50,
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 3)],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/elegant_car.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 4. السائقات القريبات الوهميات (لزيادة التفاعل)
    for (final loc in nearbyDrivers) {
      markers.add(
        Marker(
          point: loc,
          width: 44,
          height: 44,
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.8), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 6)],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/elegant_car.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    }

    bool isLightMode = (DateTime.now().hour >= 6 && DateTime.now().hour < 18);

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                onPositionChanged: (position, hasGesture) {
                  if (onCenterChanged != null) {
                    onCenterChanged!(position.center);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // منع تدوير الخريطة لتخفيف الاستهلاك
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: isLightMode
                      ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png' // Light/Day map
                      : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png', // VIP Dark map
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.doraa',
                ),
                if (routePolyline != null && routePolyline!.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Outer glow / outline for better visibility in daylight
                      Polyline(
                        points: routePolyline!,
                        color: Colors.black.withValues(alpha: 0.8),
                        strokeWidth: 10.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                      Polyline(
                        points: routePolyline!,
                        color: const Color(0xFFFFD700), // VIP Gold
                        strokeWidth: 5.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              top: 50,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'map_mode_toggle_${center.latitude}',
                mini: true,
                elevation: 4,
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFFFFD700),
                onPressed: () {
                  setState(() {
                    isLightMode = !isLightMode;
                  });
                },
                child: Icon(isLightMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}
