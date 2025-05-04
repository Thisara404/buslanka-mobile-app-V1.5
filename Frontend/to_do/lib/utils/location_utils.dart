import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class LocationUtils {
  // Get distance between two coordinates in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    // Using Haversine formula to calculate distance
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 -
        cos((point2.latitude - point1.latitude) * p) / 2 +
        cos(point1.latitude * p) *
            cos(point2.latitude * p) *
            (1 - cos((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * 1000 * asin(sqrt(a)); // 2 * R * asin(...)
  }

  // Get human-readable address from coordinates
  static Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Get coordinates from address
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);

      if (locations.isNotEmpty) {
        geo.Location location = locations[0];
        return LatLng(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  // Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    return serviceEnabled && permissionGranted == PermissionStatus.granted;
  }

  // Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // Format estimated time for display
  static String formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      return '$hours h ${mins > 0 ? '$mins min' : ''}';
    }
  }
}
