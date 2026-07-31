import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteData {
  final List<LatLng> polyline;
  final double distanceKm;
  final int durationMinutes;

  RouteData({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RoutingService {
  static const String _osrmBaseUrl = 'http://router.project-osrm.org/route/v1/driving';

  Future<RouteData?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
          '$_osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline');
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          final geometry = route['geometry'] as String;
          final distanceKm = (route['distance'] as num) / 1000.0;
          final durationMinutes = ((route['duration'] as num) / 60.0).round();
          
          return RouteData(
            polyline: _decodePolyline(geometry),
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
          );
        }
      }
    } catch (e) {
      // Return null on failure (e.g. offline, timeout)
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
