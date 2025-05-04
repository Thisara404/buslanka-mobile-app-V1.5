import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:to_do/config/config.dart';
import 'package:to_do/config/maps_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MapUtils {
  // Convert backend coordinates [lng, lat] to LatLng
  static LatLng coordinatesToLatLng(List<dynamic> coordinates) {
    return LatLng(coordinates[1].toDouble(), coordinates[0].toDouble());
  }

  // Convert stops from backend format to map markers
  static Set<Marker> stopsToMarkers(List<dynamic> stops, {Color? color}) {
    Set<Marker> markers = {};

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop['location'] != null && stop['location']['coordinates'] != null) {
        final coordinates = stop['location']['coordinates'];
        final position = coordinatesToLatLng(coordinates);

        markers.add(
          Marker(
            markerId: MarkerId('stop_${stop['_id']}'),
            position: position,
            infoWindow: InfoWindow(
              title: stop['name'] ?? 'Stop ${i + 1}',
              snippet: 'Bus stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              color != null
                  ? BitmapDescriptor.hueRed
                  : MapsConfig.stopMarkerHue,
            ),
          ),
        );
      }
    }

    return markers;
  }

  // Get current user location
  static Future<LocationData?> getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  // Draw polyline on map based on points
  static Set<Polyline> createPolylines(List<LatLng> polylineCoordinates) {
    Set<Polyline> polylines = {};

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoordinates,
        color: Color(MapsConfig.routePolylineColor),
        width: 5,
      ),
    );

    return polylines;
  }

  // Find the bounding box for given set of coordinates to fit map view
  static LatLngBounds getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      // Default to a small area in case of no points
      final center = const LatLng(6.9271, 79.8612); // Colombo
      return LatLngBounds(
        southwest: LatLng(center.latitude - 0.01, center.longitude - 0.01),
        northeast: LatLng(center.latitude + 0.01, center.longitude + 0.01),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add padding (about 10% of the total span)
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  // Alias for getBounds to match function name used in RouteDetailMapScreen
  static LatLngBounds boundsFromLatLngList(List<LatLng> points) {
    return getBounds(points);
  }

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) *
            c(point2.latitude * p) *
            (1 - c((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Check if dark mode is enabled
  static Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }

  // Get map style based on dark mode setting
  static Future<String> getMapStyle() async {
    final isDarkMode = await isDarkModeEnabled();
    return isDarkMode ? MapsConfig.nightMapStyle : MapsConfig.dayMapStyle;
  }

  // Animate camera to show all markers
  static Future<void> animateCameraToShowMarkers(
    GoogleMapController controller,
    Set<Marker> markers,
  ) async {
    if (markers.isEmpty) return;

    final points = markers.map((marker) => marker.position).toList();
    final bounds = getBounds(points);

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  // Create a custom bus marker
  static Future<BitmapDescriptor> createBusMarker({
    required Color color,
    required String label,
    double size = 40,
  }) async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    // Note: This is a placeholder implementation
    // In a production app, you would implement custom marker creation using:
    // - BitmapDescriptor.fromAssetImage()
    // - Or BitmapDescriptor.fromBytes() with a custom-drawn canvas
  }
}
