import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// Data class to hold a ghost car's route and current progress
class GhostCarData {
  List<LatLng> route;
  int currentRouteIndex;
  
  GhostCarData({required this.route, this.currentRouteIndex = 0});
}

class GhostSimulationState {
  final List<LatLng> ghostDrivers;
  final List<LatLng> ghostRiders;

  GhostSimulationState({
    required this.ghostDrivers,
    required this.ghostRiders,
  });

  GhostSimulationState copyWith({
    List<LatLng>? ghostDrivers,
    List<LatLng>? ghostRiders,
  }) {
    return GhostSimulationState(
      ghostDrivers: ghostDrivers ?? this.ghostDrivers,
      ghostRiders: ghostRiders ?? this.ghostRiders,
    );
  }
}

class GhostSimulationNotifier extends StateNotifier<GhostSimulationState> {
  GhostSimulationNotifier()
      : super(GhostSimulationState(ghostDrivers: [], ghostRiders: []));

  Timer? _timer;
  LatLng? _centerLocation;
  final math.Random _random = math.Random();
  
  // Keep track of the actual route for each car
  final List<GhostCarData> _ghostCars = [];
  
  void startSimulation(LatLng center) {
    _centerLocation = center;
    if (_timer != null) return; // Already running

    _initializeGhostRiders(center);
    _initializeGhostCars(center);

    // Update positions smoothly
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _updateGhostCarsPosition();
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _ghostCars.clear();
    state = GhostSimulationState(ghostDrivers: [], ghostRiders: []);
  }

  void _initializeGhostRiders(LatLng center) {
    List<LatLng> riders = [];
    // Generate 3 static ghost riders
    for (int i = 0; i < 3; i++) {
      riders.add(_getRandomLocation(center, 500, 1500)); 
    }
    state = state.copyWith(ghostRiders: riders);
  }

  Future<void> _initializeGhostCars(LatLng center) async {
    _ghostCars.clear();
    // Start with 4 ghost cars
    for (int i = 0; i < 4; i++) {
      await _spawnNewGhostCar(center);
    }
    _syncStateWithCars();
  }

  Future<void> _spawnNewGhostCar(LatLng center) async {
    // Start point (1km to 2km away)
    LatLng start = _getRandomLocation(center, 1000, 2000);
    // End point (1.5km to 3km away)
    LatLng end = _getRandomLocation(center, 1500, 3000); 
    
    // Fetch route from OSRM to ensure it moves on actual roads!
    List<LatLng> route = await _fetchRouteFromOSRM(start, end);
    
    if (route.isNotEmpty) {
      _ghostCars.add(GhostCarData(route: route, currentRouteIndex: 0));
    }
  }

  void _updateGhostCarsPosition() {
    if (_centerLocation == null) return;
    
    bool needsStateUpdate = false;
    
    for (int i = 0; i < _ghostCars.length; i++) {
      var car = _ghostCars[i];
      if (car.currentRouteIndex < car.route.length - 1) {
        car.currentRouteIndex += _random.nextInt(3) + 1; // move 1 to 3 nodes
        if (car.currentRouteIndex >= car.route.length) {
          car.currentRouteIndex = car.route.length - 1;
        }
        
        // SAFE DISTANCE ALGORITHM: Ensure it doesn't get closer than 400 meters to the real user
        LatLng currentPos = car.route[car.currentRouteIndex];
        double distanceToUser = _calculateDistance(_centerLocation!, currentPos);
        if (distanceToUser < 400) {
          // It's too close! We force it to finish this route and spawn a new one far away.
          car.currentRouteIndex = car.route.length; 
        }
        
        needsStateUpdate = true;
      } else {
        // Reached destination or forced to stop, spawn a new one
        _ghostCars.removeAt(i);
        i--;
        _spawnNewGhostCar(_centerLocation!);
      }
    }
    
    if (needsStateUpdate) {
      _syncStateWithCars();
    }
  }
  
  void _syncStateWithCars() {
    List<LatLng> currentPositions = _ghostCars
        .where((car) => car.currentRouteIndex < car.route.length)
        .map((car) => car.route[car.currentRouteIndex])
        .toList();
    
    state = state.copyWith(ghostDrivers: currentPositions);
  }

  LatLng _getRandomLocation(LatLng center, double minRadiusMeters, double maxRadiusMeters) {
    double radiusInDegreesMin = minRadiusMeters / 111320.0;
    double radiusInDegreesMax = maxRadiusMeters / 111320.0;
    
    double u = _random.nextDouble();
    double v = _random.nextDouble();
    double w = radiusInDegreesMax * math.sqrt(u);
    if (w < radiusInDegreesMin) {
        w = radiusInDegreesMin + (w % (radiusInDegreesMax - radiusInDegreesMin));
    }
    
    double t = 2 * math.pi * v;
    double x = w * math.cos(t);
    double y = w * math.sin(t);

    double newLng = x / math.cos(center.latitude * math.pi / 180);

    return LatLng(center.latitude + y, center.longitude + newLng);
  }
  
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371000; // Earth radius in meters
    double lat1 = point1.latitude * math.pi / 180;
    double lat2 = point2.latitude * math.pi / 180;
    double dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    double dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(lat1) * math.cos(lat2) *
               math.sin(dLng / 2) * math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  // Fetches a real road path from OpenStreetMap (OSRM)
  Future<List<LatLng>> _fetchRouteFromOSRM(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
          
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      // Ignore errors silently to not spam logs
    }
    // Fallback: If OSRM fails, return a straight line
    return _generateStraightLine(start, end);
  }
  
  List<LatLng> _generateStraightLine(LatLng start, LatLng end) {
    List<LatLng> points = [];
    int steps = 20;
    for (int i = 0; i <= steps; i++) {
      double lat = start.latitude + (end.latitude - start.latitude) * (i / steps);
      double lng = start.longitude + (end.longitude - start.longitude) * (i / steps);
      points.add(LatLng(lat, lng));
    }
    return points;
  }
}

final ghostSimulationProvider = StateNotifierProvider<GhostSimulationNotifier, GhostSimulationState>((ref) {
  return GhostSimulationNotifier();
});
