import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final Location _location = Location();
  static bool _isInitialized = false;

  // Initialize location service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Enable background mode for location updates
      await _location.enableBackgroundMode(enable: true);

      // Set location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: 10, // 10 meters
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  // Check if location permission is granted
  static Future<bool> checkPermission() async {
    try {
      PermissionStatus permission = await _location.hasPermission();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permission
  static Future<bool> requestPermission() async {
    try {
      PermissionStatus permission = await _location.requestPermission();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location service is enabled
  static Future<bool> isServiceEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  // Request to enable location service
  static Future<bool> requestService() async {
    try {
      return await _location.requestService();
    } catch (e) {
      print('Error requesting location service: $e');
      return false;
    }
  }

  // Get current location
  static Future<LocationData?> getCurrentLocation() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        hasPermission = await requestPermission();
        if (!hasPermission) return null;
      }

      bool serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await requestService();
        if (!serviceEnabled) return null;
      }

      return await _location.getLocation();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get LatLng from location data
  static LatLng? locationDataToLatLng(LocationData? locationData) {
    if (locationData == null ||
        locationData.latitude == null ||
        locationData.longitude == null) {
      return null;
    }
    return LatLng(locationData.latitude!, locationData.longitude!);
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  // Set location tracking enabled in preferences
  static Future<void> setLocationTrackingEnabled(bool enabled) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationTrackingEnabled', enabled);
    } catch (e) {
      print('Error setting location tracking preference: $e');
    }
  }

  // Check if location tracking is enabled in preferences
  static Future<bool> isLocationTrackingEnabled() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('locationTrackingEnabled') ?? true;
    } catch (e) {
      print('Error checking location tracking preference: $e');
      return true; // Default to enabled
    }
  }

  // Start location tracking
  static Stream<LocationData> getLocationStream() {
    // Initialize if not already
    if (!_isInitialized) {
      initialize();
    }

    // Return the location stream
    return _location.onLocationChanged;
  }
}
