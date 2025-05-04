import 'package:google_maps_flutter/google_maps_flutter.dart';
// Additional imports needed for the passesNear method
import 'dart:math';

class RouteStop {
  final String id;
  final String name;
  final LatLng location;

  RouteStop({
    required this.id,
    required this.name,
    required this.location,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location']['coordinates'] ?? [0.0, 0.0];
    return RouteStop(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed Stop',
      location: LatLng(
        coordinates[1].toDouble(), 
        coordinates[0].toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'location': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude]
      },
    };
  }
}

class BusRoute {
  final String id;
  final String name;
  final String? description;
  final List<RouteStop> stops;
  final List<LatLng> path;
  final double distance; // in kilometers
  final int estimatedDuration; // in minutes
  final List<String> scheduleIds;
  // final List<String> vehicleIds;

  BusRoute({
    required this.id,
    required this.name,
    this.description,
    required this.stops,
    required this.path,
    this.distance = 0.0,
    this.estimatedDuration = 0,
    this.scheduleIds = const [],
    // this.vehicleIds = const [],
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    // Parse stops
    final stops = (json['stops'] as List?)?.map((stop) => RouteStop.fromJson(stop)).toList() ?? [];

    // Parse path coordinates
    final pathCoordinates = (json['path']?['coordinates'] as List?)?.map((coord) {
      if (coord is List) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }
      return LatLng(0, 0);
    }).toList() ?? [];

    // Parse schedules and vehicles IDs
    final scheduleIds = (json['schedules'] as List?)?.map((s) => s.toString()).toList() ?? [];
    final vehicleIds = (json['vehicles'] as List?)?.map((v) => v.toString()).toList() ?? [];

    return BusRoute(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed Route',
      description: json['description'],
      stops: stops,
      path: pathCoordinates,
      distance: (json['distance'] ?? 0).toDouble(),
      estimatedDuration: (json['estimatedDuration'] ?? 0).toInt(),
      scheduleIds: scheduleIds,
      // vehicleIds: vehicleIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'path': {
        'type': 'LineString',
        'coordinates': path.map((point) => [point.longitude, point.latitude]).toList(),
      },
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'schedules': scheduleIds,
      // 'vehicles': vehicleIds,
    };
  }

  // Get first and last stop names for display
  String getRouteEndpoints() {
    if (stops.isEmpty) return 'No stops';
    if (stops.length == 1) return stops.first.name;
    return '${stops.first.name} → ${stops.last.name}';
  }

  // Check if this route passes through a location
  bool passesNear(LatLng location, double maxDistanceMeters) {
    // Simple implementation - check if any stop is within range
    for (var stop in stops) {
      final latLngA = location;
      final latLngB = stop.location;
      
      // Calculate distance using haversine formula
      const double earthRadius = 6371000; // in meters
      final dLat = (latLngB.latitude - latLngA.latitude) * (pi / 180);
      final dLon = (latLngB.longitude - latLngA.longitude) * (pi / 180);
      
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(latLngA.latitude * (pi / 180)) * 
          cos(latLngB.latitude * (pi / 180)) *
          sin(dLon / 2) * sin(dLon / 2);
      
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final distance = earthRadius * c;
      
      if (distance <= maxDistanceMeters) {
        return true;
      }
    }
    return false;
  }

  // Get a specific stop by ID
  RouteStop? getStopById(String stopId) {
    try {
      return stops.firstWhere((stop) => stop.id == stopId);
    } catch (_) {
      return null;
    }
  }
}

