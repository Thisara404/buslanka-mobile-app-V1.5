import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/services/schedule_service.dart';
import 'package:to_do/utils/map_utils.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class StartRouteScreen extends StatefulWidget {
  final String vehicleId;
  final String routeId;
  final String scheduleName;
  final String scheduleId;

  const StartRouteScreen({
    Key? key,
    required this.vehicleId,
    required this.routeId,
    required this.scheduleName,
    required this.scheduleId,
  }) : super(key: key);

  @override
  State<StartRouteScreen> createState() => _StartRouteScreenState();
}

class _StartRouteScreenState extends State<StartRouteScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Map<String, dynamic>? _routeData;
  List<dynamic>? _stopTimes;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _inProgress = false;
  int _currentStopIndex = 0;
  String? _errorMessage;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load route data
      final routeData = await RouteService.getRouteById(widget.routeId);

      // Load schedule times
      Map<String, dynamic> scheduleData =
          await ScheduleService.getEstimatedArrivalTimes(widget.scheduleId);

      setState(() {
        _routeData = routeData;
        _stopTimes = scheduleData['stopTimes'] ?? [];
        _isLoading = false;
      });

      // Set up map elements
      _initializeMapElements();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route: $e';
      });
      print('Error loading route data: $e');
    }
  }

  void _initializeMapElements() {
    if (_routeData == null) return;

    final stops = _routeData!['stops'] ?? [];

    // Create stop markers
    _markers = {};
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop['location'] != null && stop['location']['coordinates'] != null) {
        final coordinates = stop['location']['coordinates'];
        final position = LatLng(coordinates[1], coordinates[0]);
        final bool isNextStop = i == _currentStopIndex;

        _markers.add(
          Marker(
            markerId: MarkerId('stop_${stop['_id']}'),
            position: position,
            infoWindow: InfoWindow(
              title: stop['name'] ?? 'Stop ${i + 1}',
              snippet: isNextStop ? 'Next Stop' : 'Bus Stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isNextStop ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    // Create route polyline
    if (_routeData!['path'] != null &&
        _routeData!['path']['coordinates'] != null) {
      final coordinates = _routeData!['path']['coordinates'] as List;
      List<LatLng> polylinePoints = [];

      for (var coordinate in coordinates) {
        polylinePoints.add(LatLng(coordinate[1], coordinate[0]));
      }

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      };
    }
  }

  Future<void> _startRoute() async {
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      // Request location permission if not already granted
      bool hasPermission = await locationProvider.requestLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Location permission is required to start the route')),
        );
        return;
      }

      // Start location tracking
      await locationProvider.startLocationTracking();

      // Update schedule status to in-progress
      await ScheduleService.updateScheduleStatus(
          widget.scheduleId, widget.vehicleId, 'in-progress');

      setState(() {
        _inProgress = true;
      });

      // Set up location update timer
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _updateVehicleLocation(),
      );

      // Fit map to route with vehicle at current stop
      _animateToCurrentStop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route started successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting route: $e')),
      );
    }
  }

  Future<void> _updateVehicleLocation() async {
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      final currentLocation = locationProvider.currentLatLng;
      if (currentLocation == null) return;

      // In a real app, you would send the location to the server
      // For now, just update the UI
      setState(() {
        // Add a vehicle marker at the current location
        _markers = {
          ..._markers
              .where((marker) => !marker.markerId.value.startsWith('vehicle_')),
          Marker(
            markerId: const MarkerId('vehicle_current'),
            position: currentLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: 'Current Location',
              snippet: 'Your vehicle is here',
            ),
          ),
        };
      });
    } catch (e) {
      print('Error updating vehicle location: $e');
    }
  }

  Future<void> _completeRoute() async {
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      // Stop location tracking
      await locationProvider.stopLocationTracking();

      // Update schedule status
      await ScheduleService.updateScheduleStatus(
          widget.scheduleId, widget.vehicleId, 'completed');

      // Go back to driver home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route completed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing route: $e')),
      );
    }
  }

  Future<void> _reachedCurrentStop() async {
    if (_routeData == null || _stopTimes == null) return;

    final stops = _routeData!['stops'];
    if (_currentStopIndex >= stops.length - 1) {
      // Last stop reached, complete the route
      await _completeRoute();
      return;
    }

    // Move to next stop
    setState(() {
      _currentStopIndex++;
    });

    // Update map markers
    _initializeMapElements();

    // Animate to next stop
    final nextStop = stops[_currentStopIndex];
    final coordinates = nextStop['location']['coordinates'];
    final position = LatLng(coordinates[1], coordinates[0]);

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  Future<void> _animateToCurrentStop() async {
    if (_routeData == null || !_mapController.isCompleted) return;

    final stops = _routeData!['stops'];
    if (stops == null || stops.isEmpty || _currentStopIndex >= stops.length)
      return;

    final currentStop = stops[_currentStopIndex];
    if (currentStop['location'] == null ||
        currentStop['location']['coordinates'] == null) return;

    final coordinates = currentStop['location']['coordinates'];
    final position = LatLng(coordinates[1], coordinates[0]);

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  void _fitMapToRoute() async {
    if (_routeData == null || !_mapController.isCompleted) return;

    List<LatLng> points = [];

    // Add all stops to points
    for (var stop in _routeData!['stops']) {
      final coordinates = stop['location']['coordinates'];
      points.add(LatLng(coordinates[1], coordinates[0]));
    }

    // Add current vehicle location if available
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLatLng != null) {
      points.add(locationProvider.currentLatLng!);
    }

    if (points.isEmpty) return;

    final bounds = LatLngBounds(
      southwest: _findSouthWestBound(points),
      northeast: _findNorthEastBound(points),
    );

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLng _findSouthWestBound(List<LatLng> points) {
    double minLat = points.first.latitude;
    double minLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
    }

    return LatLng(minLat, minLng);
  }

  LatLng _findNorthEastBound(List<LatLng> points) {
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLng(maxLat, maxLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheduleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fitMapToRoute,
            tooltip: 'Fit route to screen',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: 'Loading route...'))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRouteData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Map view
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _routeData != null &&
                                      _routeData!['stops'].isNotEmpty
                                  ? LatLng(
                                      _routeData!['stops'][0]['location']
                                          ['coordinates'][1],
                                      _routeData!['stops'][0]['location']
                                          ['coordinates'][0],
                                    )
                                  : const LatLng(
                                      6.9271, 79.8612), // Default to Colombo
                              zoom: 15,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: true,
                            mapType: MapType.normal,
                            onMapCreated: (controller) {
                              _mapController.complete(controller);
                              _fitMapToRoute();
                            },
                          ),

                          // Current status indicator
                          if (_inProgress)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'IN PROGRESS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Current/next stop card
                    if (_routeData != null && _stopTimes != null)
                      _buildCurrentStopCard(),

                    // Start/Complete route button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _inProgress
                            ? ElevatedButton.icon(
                                onPressed: _routeData != null &&
                                        _currentStopIndex <
                                            _routeData!['stops'].length
                                    ? _reachedCurrentStop
                                    : _completeRoute,
                                icon: const Icon(Icons.check_circle),
                                label: Text(
                                  _routeData != null &&
                                          _currentStopIndex >=
                                              _routeData!['stops'].length - 1
                                      ? 'COMPLETE ROUTE'
                                      : 'ARRIVED AT STOP',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _routeData != null &&
                                          _currentStopIndex >=
                                              _routeData!['stops'].length - 1
                                      ? Colors.green
                                      : Theme.of(context).primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _startRoute,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('START ROUTE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCurrentStopCard() {
    if (_routeData == null ||
        _stopTimes == null ||
        _routeData!['stops'].isEmpty) return Container();

    final currentStop = _currentStopIndex < _routeData!['stops'].length
        ? _routeData!['stops'][_currentStopIndex]
        : _routeData!['stops'].last;

    final stopName = currentStop['name'] ?? 'Unknown Stop';
    final stopId = currentStop['_id'];

    // Find corresponding stop time
    final stopTimeData = _stopTimes!.firstWhere(
      (time) => time['stopId'] == stopId,
      orElse: () => {'arrivalTime': null, 'departureTime': null},
    );

    final arrivalTime = stopTimeData['arrivalTime'] != null
        ? DateTime.parse(stopTimeData['arrivalTime'])
        : null;
    final departureTime = stopTimeData['departureTime'] != null
        ? DateTime.parse(stopTimeData['departureTime'])
        : null;

    final timeFormat = DateFormat('HH:mm');
    final arrivalFormatted =
        arrivalTime != null ? timeFormat.format(arrivalTime) : 'N/A';
    final departureFormatted =
        departureTime != null ? timeFormat.format(departureTime) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_currentStopIndex + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStopIndex >= _routeData!['stops'].length - 1
                        ? 'Final Stop'
                        : 'Next Stop',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  Text(
                    stopName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeDisplay(
                label: 'Scheduled Arrival',
                time: arrivalFormatted,
                icon: Icons.access_time,
              ),
              _buildTimeDisplay(
                label: 'Scheduled Departure',
                time: departureFormatted,
                icon: Icons.departure_board,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required String time,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
