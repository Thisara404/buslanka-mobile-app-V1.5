import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/models/route.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/services/socket_service.dart';
import 'package:to_do/utils/map_utils.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';
import 'package:to_do/screens/map/stop_details_screen.dart';

class RouteViewerScreen extends StatefulWidget {
  final String routeId;
  final String routeName;
  final bool showActiveVehicles;

  const RouteViewerScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
    this.showActiveVehicles = true,
  }) : super(key: key);

  @override
  State<RouteViewerScreen> createState() => _RouteViewerScreenState();
}

class _RouteViewerScreenState extends State<RouteViewerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _routeData;
  Set<Marker> _stopMarkers = {};
  Set<Polyline> _routePolylines = {};

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    // // Untrack vehicles when leaving the screen
    // if (widget.showActiveVehicles) {
    //   final vehicleProvider =
    //       Provider.of<VehicleProvider>(context, listen: false);
    //   vehicleProvider.untrackRoute(widget.routeId);
    // }
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get route data
      _routeData = await RouteService.getRouteById(widget.routeId);

      // Process route data into map elements
      _processRouteData();

      // // Track active vehicles on this route
      // if (widget.showActiveVehicles) {
      //   final vehicleProvider =
      //       Provider.of<VehicleProvider>(context, listen: false);
      //   vehicleProvider.trackRoute(widget.routeId);
      // }

      // Connect to socket for real-time updates
      await SocketService.initSocket();
      SocketService.subscribeToRoute(widget.routeId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route: $e';
      });
      print('Error loading route data: $e');
    }
  }

  void _processRouteData() {
    if (_routeData == null) return;

    // Create markers for stops
    _stopMarkers = _createStopMarkers();

    // Create polyline for route path
    _routePolylines = _createRoutePolyline();
  }

  Set<Marker> _createStopMarkers() {
    Set<Marker> markers = {};
    final stops = _routeData!['stops'] as List<dynamic>;

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];

      if (stop['location'] != null && stop['location']['coordinates'] != null) {
        final coordinates = stop['location']['coordinates'];
        final position = LatLng(coordinates[1], coordinates[0]);

        markers.add(
          Marker(
            markerId: MarkerId('stop_${stop['_id']}'),
            position: position,
            infoWindow: InfoWindow(
              title: stop['name'] ?? 'Stop ${i + 1}',
              snippet: 'Tap for details',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(i == 0
                ? BitmapDescriptor.hueGreen
                : i == stops.length - 1
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange),
            onTap: () => _showStopDetails(stop, i, stops.length),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _createRoutePolyline() {
    Set<Polyline> polylines = {};

    if (_routeData!['path'] != null &&
        _routeData!['path']['coordinates'] != null) {
      final coordinates = _routeData!['path']['coordinates'] as List<dynamic>;
      List<LatLng> polylinePoints = [];

      for (var coordinate in coordinates) {
        polylinePoints.add(LatLng(coordinate[1], coordinate[0]));
      }

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    return polylines;
  }

  void _showStopDetails(Map<String, dynamic> stop, int index, int totalStops) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopDetailsScreen(
          stop: stop,
          routeId: widget.routeId,
          stopIndex: index,
          totalStops: totalStops,
          routeName: widget.routeName,
        ),
      ),
    );
  }

  Future<void> _fitMapToRoute() async {
    if (_routeData == null || !_controller.isCompleted) return;

    List<LatLng> points = [];

    // Add all stops to points
    for (var stop in _routeData!['stops']) {
      if (stop['location'] != null && stop['location']['coordinates'] != null) {
        final coordinates = stop['location']['coordinates'];
        points.add(LatLng(coordinates[1], coordinates[0]));
      }
    }

    // Add user location if available
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLatLng != null) {
      points.add(locationProvider.currentLatLng!);
    }

    if (points.isEmpty) return;

    final bounds = MapUtils.getBounds(points);
    final controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // // Get vehicle markers
    // Set<Marker> allMarkers = {..._stopMarkers};
    // if (widget.showActiveVehicles) {
    //   final vehicleProvider = Provider.of<VehicleProvider>(context);
    //   allMarkers = {...allMarkers, ...vehicleProvider.markers};
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fitMapToRoute,
            tooltip: 'Show entire route',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading route map...')
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
              : Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
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
                        zoom: 14.0,
                      ),
                      // markers: allMarkers,
                      polylines: _routePolylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _fitMapToRoute();
                        });
                      },
                    ),

                    // Bottom route info card
                    if (_routeData != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Route Information',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Distance: ${(_routeData!['distance'] ?? 0) / 1000} km',
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.place,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _routeData!['stops'].isNotEmpty
                                            ? 'From: ${_routeData!['stops'][0]['name'] ?? 'Start'}'
                                            : 'From: Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _routeData!['stops'].isNotEmpty
                                            ? 'To: ${_routeData!['stops'].last['name'] ?? 'End'}'
                                            : 'To: Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
