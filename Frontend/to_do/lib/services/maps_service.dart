import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:to_do/config/config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapsService {
  // Get directions between two points
  static Future<Map<String, dynamic>> getDirections(
      LatLng origin, LatLng destination) async {
    try {
      final routeId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create a temporary route object with just the start and end points
      final routeData = {
        'name': 'Temporary Route',
        'stops': [
          {
            'name': 'Start',
            'location': {
              'type': 'Point',
              'coordinates': [origin.longitude, origin.latitude]
            }
          },
          {
            'name': 'End',
            'location': {
              'type': 'Point',
              'coordinates': [destination.longitude, destination.latitude]
            }
          }
        ]
      };
      
      // Use the route directions endpoint
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routeDirectionsEndpoint}/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'originLng': origin.longitude,
          'originLat': origin.latitude,
          'destinationLng': destination.longitude,
          'destinationLat': destination.latitude,
          'stops': []
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to get directions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get directions: $e');
    }
  }

  // Geocode an address to coordinates
  static Future<LatLng> geocodeAddress(String address) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.geocodeEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return LatLng(result['data']['lat'], result['data']['lng']);
      } else {
        throw Exception(
          'Failed to geocode address: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to geocode address: $e');
    }
  }

  // Get distance and duration between two points
  static Future<Map<String, dynamic>> getDistanceMatrix(
      LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.routeDirectionsEndpoint}/distance-matrix');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': {'lat': origin.latitude, 'lng': origin.longitude},
          'destination': {
            'lat': destination.latitude,
            'lng': destination.longitude
          },
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get distance matrix: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get distance matrix: $e');
    }
  }

  // Convert directions API response to polyline points
  static List<LatLng> decodePolyline(String encodedPolyline) {
    try {
      List<PointLatLng> points = PolylinePoints().decodePolyline(encodedPolyline);
      return points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  // Create a polyline from a list of points
  static Polyline createPolyline(
      {required String id,
      required List<LatLng> points,
      required Color color,
      int width = 5}) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: color,
      width: width,
    );
  }
  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    // Convert coordinates to radians
    final lat1 = point1.latitude * (pi / 180);
    final lng1 = point1.longitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final lng2 = point2.longitude * (pi / 180);

    // Haversine formula
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c; // Distance in meters
  }
  // static import 'dart:math' show sin, cos, sqrt, atan2, pi;
}