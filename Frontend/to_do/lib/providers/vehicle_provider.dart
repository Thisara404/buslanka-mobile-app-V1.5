// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:to_do/services/vehicle_service.dart';
// import 'package:to_do/services/socket_service.dart';
// import 'package:to_do/utils/map_utils.dart';

// class VehicleProvider extends ChangeNotifier {
//   Map<String, dynamic> _activeVehicles = {};
//   final Map<String, Marker> _vehicleMarkers = {};
//   bool _isLoading = false;
//   String? _error;
//   Timer? _refreshTimer;
//   Set<String> _trackedRouteIds = {};
//   bool _isInitialized = false;

//   Map<String, dynamic> get activeVehicles => _activeVehicles;
//   Map<String, Marker> get vehicleMarkers => _vehicleMarkers;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   Set<Marker> get markers => _vehicleMarkers.values.toSet();

//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       // Initialize socket service if not already initialized
//       await SocketService.initSocket();
//       setupSocketListeners();
//       _isInitialized = true;
//     } catch (e) {
//       _error = 'Failed to initialize vehicle tracking: $e';
//       print('Failed to initialize vehicle tracking: $e');
//     }
//   }

//   void startTracking() {
//     // Initialize if not already initialized
//     if (!_isInitialized) {
//       initialize();
//     }

//     // Set up periodic refresh (every 30 seconds)
//     _refreshTimer?.cancel();
//     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       refreshVehicleLocations();
//     });
//   }

//   void stopTracking() {
//     _refreshTimer?.cancel();
//     _trackedRouteIds.clear();
//   }

//   Future<void> trackRoute(String routeId) async {
//     if (!_isInitialized) {
//       await initialize();
//     }

//     _trackedRouteIds.add(routeId);
//     await _loadVehiclesByRoute(routeId);
//     SocketService.subscribeToRoute(routeId);
//   }

//   void untrackRoute(String routeId) {
//     _trackedRouteIds.remove(routeId);
//     SocketService.unsubscribeFromRoute(routeId);

//     // Remove vehicles associated with this route
//     _activeVehicles.removeWhere((key, vehicle) =>
//         vehicle['route'] != null && vehicle['route']['_id'] == routeId);

//     // Remove markers for these vehicles
//     _vehicleMarkers.removeWhere((key, marker) => _activeVehicles[key] == null);

//     notifyListeners();
//   }

//   Future<void> _loadVehiclesByRoute(String routeId) async {
//     try {
//       final vehicles = await VehicleService.getVehiclesByRoute(routeId);

//       // Process vehicles
//       for (var vehicle in vehicles) {
//         if (vehicle['currentLocation'] != null && vehicle['_id'] != null) {
//           _activeVehicles[vehicle['_id']] = vehicle;
//           _addVehicleMarker(vehicle);
//         }
//       }

//       notifyListeners();
//     } catch (e) {
//       _error = 'Failed to load vehicles for route';
//       print('Failed to load vehicles for route: $e');
//     }
//   }

//   void _addVehicleMarker(Map<String, dynamic> vehicle) {
//     if (vehicle['currentLocation'] == null ||
//         vehicle['currentLocation']['coordinates'] == null ||
//         vehicle['_id'] == null) {
//       return;
//     }

//     final coordinates = vehicle['currentLocation']['coordinates'];
//     final position = MapUtils.coordinatesToLatLng(coordinates);
//     final vehicleId = vehicle['_id'];
//     final busNumber = vehicle['busNumber'] ?? 'Unknown';
//     final status = vehicle['status'] ?? 'Active';

//     _vehicleMarkers[vehicleId] = Marker(
//       markerId: MarkerId('vehicle_$vehicleId'),
//       position: position,
//       infoWindow: InfoWindow(
//         title: 'Bus $busNumber',
//         snippet: 'Status: $status',
//       ),
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//     );
//   }

//   Future<void> refreshVehicleLocations() async {
//     if (_trackedRouteIds.isEmpty) return;

//     _isLoading = true;
//     notifyListeners();

//     try {
//       for (final routeId in _trackedRouteIds) {
//         await _loadVehiclesByRoute(routeId);
//       }
//     } catch (e) {
//       _error = 'Failed to refresh vehicle locations';
//       print('Failed to refresh vehicle locations: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void updateVehicleLocation(Map<String, dynamic> vehicleData) {
//     final vehicleId = vehicleData['_id'];
//     if (vehicleId == null) return;

//     _activeVehicles[vehicleId] = vehicleData;
//     _addVehicleMarker(vehicleData);
//     notifyListeners();
//   }

//   void setupSocketListeners() {
//     // Listen for vehicle location updates
//     SocketService.addListener('vehicle:location:changed', (data) {
//       updateVehicleLocation(data);
//     });

//     // Listen for vehicle status updates
//     SocketService.addListener('vehicle:status:changed', (data) {
//       final vehicleId = data['_id'];
//       if (vehicleId != null && _activeVehicles.containsKey(vehicleId)) {
//         _activeVehicles[vehicleId]['status'] = data['status'];
//         _addVehicleMarker(_activeVehicles[vehicleId]);
//         notifyListeners();
//       }
//     });
//   }

//   bool _isOnJourney = false;
//   bool get isOnJourney => _isOnJourney;

//   void setJourneyStatus(bool status) {
//     _isOnJourney = status;
//     notifyListeners();
//   }

//   void endJourney() {
//     _isOnJourney = false;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     stopTracking();
//     _refreshTimer?.cancel();
//     SocketService.removeListener('vehicle:location:changed');
//     SocketService.removeListener('vehicle:status:changed');
//     _activeVehicles.clear();
//     _vehicleMarkers.clear();
//     _trackedRouteIds.clear();
//     super.dispose();
//   }
// }
