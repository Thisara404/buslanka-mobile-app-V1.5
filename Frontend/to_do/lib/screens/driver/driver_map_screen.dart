import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/config/maps_config.dart';
import 'package:to_do/screens/map/map_screen.dart';
import 'package:to_do/utils/map_utils.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  // Track route and journey information
  bool _isOnJourney = false;
  String? _currentRouteName;
  String? _currentScheduleId;
  String? _nextStopName;

  // Journey statistics
  int _totalStops = 0;
  int _completedStops = 0;
  double _journeyProgress = 0.0;
  Duration _estimatedTimeRemaining = Duration.zero;

  // Map data
  Set<Marker> _routeMarkers = {};
  Set<Polyline> _routePolylines = {};

  @override
  void initState() {
    super.initState();
    // _loadRouteData();
    _startLocationUpdates();
  }

  // Future<void> _loadRouteData() async {
  //   try {
  //     // // Get vehicle provider to access current route data
  //     // final vehicleProvider =
  //     //     Provider.of<VehicleProvider>(context, listen: false);

  //     // For demonstration, we're using mock data
  //     // In real implementation, fetch this from the vehicle provider
  //     setState(() {
  //       _isOnJourney = vehicleProvider.isOnJourney;
  //       _currentRouteName = "City Center - Airport";
  //       _totalStops = 8;
  //       _completedStops = _isOnJourney ? 2 : 0;
  //       _journeyProgress = _isOnJourney ? 0.25 : 0.0;
  //       _nextStopName = _isOnJourney ? "Central Station" : null;
  //       _estimatedTimeRemaining = const Duration(minutes: 45);

  //       // Set up mock route markers and polyline
  //       _setupRouteMapElements();
  //     });

  //     // Listen for journey status changes
  //     vehicleProvider.addListener(_onVehicleStatusChanged);
  //   } catch (e) {
  //     print('Error loading route data: $e');
  //   }
  // }

  void _startLocationUpdates() {
    // Listen to location updates from the location provider
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.startLocationTracking();

    // In a real app, you would update the route progress based on location
    // For now, we'll simulate this with a timer if a journey is active
    if (_isOnJourney) {
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!_isOnJourney) {
          timer.cancel();
          return;
        }

        setState(() {
          _completedStops = (_completedStops + 1) % (_totalStops + 1);
          _journeyProgress =
              _totalStops > 0 ? _completedStops / _totalStops : 0;
          _estimatedTimeRemaining =
              Duration(minutes: max(0, 45 - (_completedStops * 5)));

          // Update next stop
          final stopNames = [
            "Central Station",
            "Market Square",
            "Hospital",
            "University",
            "Tech Park",
            "Shopping Mall",
            "Sports Stadium",
            "Airport"
          ];
          _nextStopName = _completedStops < _totalStops
              ? stopNames[_completedStops]
              : "End of Route";
        });
      });
    }
  }

  // void _onVehicleStatusChanged() {
  //   final vehicleProvider =
  //       Provider.of<VehicleProvider>(context, listen: false);
  //   setState(() {
  //     _isOnJourney = vehicleProvider.isOnJourney;

  //     // Reset journey data if journey ended
  //     if (!_isOnJourney) {
  //       _completedStops = 0;
  //       _journeyProgress = 0.0;
  //       _nextStopName = null;
  //     }
  //   });
  // }

  void _setupRouteMapElements() {
    // In a real app, this would come from API/backend
    // Mock route markers for demonstration
    _routeMarkers = {
      Marker(
        markerId: const MarkerId('start'),
        position: const LatLng(6.9271, 79.8612), // Colombo
        infoWindow: const InfoWindow(title: 'City Center'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('stop1'),
        position: const LatLng(6.9350, 79.8500),
        infoWindow: const InfoWindow(title: 'Central Station'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
      Marker(
        markerId: const MarkerId('stop2'),
        position: const LatLng(6.9400, 79.8400),
        infoWindow: const InfoWindow(title: 'Market Square'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: const LatLng(6.9500, 79.8300), // Airport area
        infoWindow: const InfoWindow(title: 'Airport'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Create a route polyline
    _routePolylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: const [
          LatLng(6.9271, 79.8612),
          LatLng(6.9350, 79.8500),
          LatLng(6.9400, 79.8400),
          LatLng(6.9500, 79.8300),
        ],
        color: Colors.blue, // Using direct color reference
        width: 5,
      ),
    };
  }

  Widget _buildJourneyStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isOnJourney) ...[
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentRouteName ?? 'Current Route',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Next stop: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: _nextStopName ?? 'N/A'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _journeyProgress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${(_journeyProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Stops: $_completedStops/$_totalStops',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'ETA: ${_estimatedTimeRemaining.inMinutes} minutes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // OutlinedButton.icon(
            //   onPressed: () {
            //   //   // End journey logic
            //   //   final vehicleProvider =
            //   //       // Provider.of<VehicleProvider>(context, listen: false);
            //   //   vehicleProvider.endJourney();
            //   // },
            //   icon: Icon(Icons.stop_circle_outlined),
            //   label: Text('END JOURNEY'),
            //   style: OutlinedButton.styleFrom(
            //     foregroundColor: Colors.red,
            //     side: BorderSide(color: Colors.red),
            //     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            //   ),
            // ),
          ] else ...[
            // No active journey
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a route from your schedule to begin tracking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to schedules screen
                      Navigator.pushNamed(context, '/driver/schedules');
                    },
                    icon: Icon(Icons.schedule),
                    label: Text('VIEW SCHEDULES'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOnJourney
            ? 'Route: ${_currentRouteName ?? "Current Journey"}'
            : 'Driver Map'),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.refresh),
          //   // onPressed: _loadRouteData,
          //   tooltip: 'Refresh Data',
          // ),
        ],
      ),
      body: Stack(
        children: [
          // Map takes most of the screen
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.9271, 79.8612), // Default to Colombo
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            markers: _routeMarkers,
            polylines: _routePolylines,
            mapType: MapType.normal,
          ),

          // Journey status panel at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildJourneyStatusPanel(),
          ),
        ],
      ),
    );
  }

  int max(int a, int b) {
    return (a > b) ? a : b;
  }
}
