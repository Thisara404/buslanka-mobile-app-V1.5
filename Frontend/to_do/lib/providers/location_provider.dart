import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:to_do/services/socket_service.dart';
import 'package:to_do/services/vehicle_service.dart';

class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  LocationData? _currentLocation;
  bool _isTracking = false;
  bool _isInBackground = false;
  Timer? _locationUpdateTimer;
  String? _driverId;
  String? _vehicleId;
  bool _permissionGranted = false;

  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get hasLocation => _currentLocation != null;
  bool get permissionGranted => _permissionGranted;

  LatLng? get currentLatLng {
    if (_currentLocation != null) {
      return LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    }
    return null;
  }

  Future<bool> requestLocationPermission() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _permissionGranted = false;
        notifyListeners();
        return false;
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _permissionGranted = false;
        notifyListeners();
        return false;
      }
    }

    _permissionGranted = true;
    notifyListeners();
    return true;
  }

  Future<bool> getCurrentLocation() async {
    if (!await requestLocationPermission()) {
      return false;
    }

    try {
      Location location = Location();
      _currentLocation = await location.getLocation();
      notifyListeners();
      return _currentLocation != null;
    } catch (e) {
      print('Error getting location: $e');
      return false;
    }
  }

  void setDriverAndVehicle(String driverId, String vehicleId) {
    _driverId = driverId;
    _vehicleId = vehicleId;
  }

  Future<bool> startLocationTracking() async {
    if (_vehicleId == null || _isTracking) return false;
    if (!await requestLocationPermission()) return false;

    try {
      await getCurrentLocation();

      // Initialize Socket
      await SocketService.initSocket();
      SocketService.startVehicleTracking(_vehicleId!);

      // Start periodic updates
      _locationUpdateTimer =
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        await _updateLocation();
      });

      _isTracking = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  Future<void> stopLocationTracking() async {
    if (_vehicleId != null) {
      SocketService.stopVehicleTracking(_vehicleId!);
    }

    _locationUpdateTimer?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _updateLocation() async {
    if (!_isTracking || _vehicleId == null) return;

    try {
      // Get updated location
      await getCurrentLocation();

      if (_currentLocation != null) {
        // Send update via Socket
        SocketService.sendVehicleLocation(
          _vehicleId!,
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        );

        // // Also send via HTTP (as backup)
        // await VehicleService.updateVehicleLocation(
        //   _vehicleId!,
        //   _currentLocation!.latitude!,
        //   _currentLocation!.longitude!,
        // );
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInBackground = state == AppLifecycleState.paused;
    configureBatteryOptimizedTracking();
  }

  Future<void> configureBatteryOptimizedTracking() async {
    // Reduce tracking frequency when app is in background
    if (_isInBackground) {
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = Timer.periodic(
          const Duration(minutes: 5), // Less frequent updates
          (_) => _updateLocation());
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
