import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';
import 'package:to_do/utils/map_utils.dart';

class RouteDetailMapScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteDetailMapScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
  }) : super(key: key);

  @override
  State<RouteDetailMapScreen> createState() => _RouteDetailMapScreenState();
}

class _RouteDetailMapScreenState extends State<RouteDetailMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Map<String, dynamic>? _routeData;
  Set<Marker> _stopMarkers = {};
  Set<Polyline> _routePolylines = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _showStops = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
    _initializeTracking();
  }

  @override
  void dispose() {
    // _stopTracking();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    // Set up vehicle provider to track this route
    // final vehicleProvider =
    //     Provider.of<VehicleProvider>(context, listen: false);
    // await vehicleProvider.trackRoute(widget.routeId);

    // Refresh route data periodically
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadRouteData();
    });
  }

  // void _stopTracking() {
  //   final vehicleProvider =
  //       Provider.of<VehicleProvider>(context, listen: false);
  //   vehicleProvider.untrackRoute(widget.routeId);
  // }

  Future<void> _loadRouteData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load route details
      final routeData = await RouteService.getRouteById(widget.routeId);

      // Process data for map display
      _processRouteData(routeData);

      setState(() {
        _routeData = routeData;
        _isLoading = false;
      });

      // Fit map to route bounds
      _fitMapToRoute();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route: $e';
      });
      print('Error loading route data: $e');
    }
  }

  void _processRouteData(Map<String, dynamic> routeData) {
    // Create stop markers
    _createStopMarkers(routeData);

    // Create route polyline
    _createRoutePolyline(routeData);
  }

  void _createStopMarkers(Map<String, dynamic> routeData) {
    final stops = routeData['stops'] ?? [];
    _stopMarkers = {};

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop['location'] != null && stop['location']['coordinates'] != null) {
        final coordinates = stop['location']['coordinates'];
        final position = LatLng(coordinates[1], coordinates[0]);

        _stopMarkers.add(
          Marker(
            markerId: MarkerId('stop_${stop['_id'] ?? i}'),
            position: position,
            infoWindow: InfoWindow(
              title: stop['name'] ?? 'Stop ${i + 1}',
              snippet: stop['description'] ?? 'Bus Stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0
                  ? BitmapDescriptor.hueGreen // Start stop
                  : i == stops.length - 1
                      ? BitmapDescriptor.hueRed // End stop
                      : BitmapDescriptor.hueViolet, // Middle stops
            ),
          ),
        );
      }
    }
  }

  void _createRoutePolyline(Map<String, dynamic> routeData) {
    _routePolylines = {};

    // Check if we have path data in the expected format
    if (routeData['path'] != null && routeData['path']['coordinates'] != null) {
      final coordinates = routeData['path']['coordinates'] as List;
      List<LatLng> polylinePoints = [];

      for (var coordinate in coordinates) {
        polylinePoints.add(LatLng(coordinate[1], coordinate[0]));
      }

      _routePolylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
    // Fallback: If no path is available but we have stops, create a line connecting the stops
    else if (routeData['stops'] != null && routeData['stops'].length > 1) {
      final stops = routeData['stops'] as List;
      List<LatLng> polylinePoints = [];

      for (var stop in stops) {
        if (stop['location'] != null &&
            stop['location']['coordinates'] != null) {
          final coordinates = stop['location']['coordinates'];
          polylinePoints.add(LatLng(coordinates[1], coordinates[0]));
        }
      }

      if (polylinePoints.length > 1) {
        _routePolylines.add(
          Polyline(
            polylineId: const PolylineId('route_path'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }

    // If we still don't have polylines, attempt to fetch directions from the API
    if (_routePolylines.isEmpty) {
      _fetchRouteDirections(routeData['_id']);
    }
  }

  // New method to fetch route directions if needed
  Future<void> _fetchRouteDirections(String routeId) async {
    try {
      final directions = await RouteService.getRouteDirections(routeId);

      if (directions['path'] != null &&
          directions['path']['coordinates'] != null) {
        final coordinates = directions['path']['coordinates'] as List;
        List<LatLng> polylinePoints = [];

        for (var coordinate in coordinates) {
          polylinePoints.add(LatLng(coordinate[1], coordinate[0]));
        }

        setState(() {
          _routePolylines.add(
            Polyline(
              polylineId: const PolylineId('route_path'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } catch (e) {
      print('Error fetching route directions: $e');
      // Silently fail - we already have markers for the stops
    }
  }

  Future<void> _fitMapToRoute() async {
    if (!_mapController.isCompleted || _routeData == null) return;

    List<LatLng> points = [];

    // Add all stops to points
    if (_routeData!['stops'] != null) {
      for (var stop in _routeData!['stops']) {
        if (stop['location'] != null &&
            stop['location']['coordinates'] != null) {
          final coordinates = stop['location']['coordinates'];
          points.add(LatLng(coordinates[1], coordinates[0]));
        }
      }
    }

    if (points.isEmpty) return;

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapUtils.boundsFromLatLngList(points),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access vehicle provider to get active buses on this route
    // final vehicleProvider = Provider.of<VehicleProvider>(context);
    // final busMarkers = vehicleProvider.markers;

    // Combine bus markers with stop markers if showing stops
    // final allMarkers = <Marker>{
    //   ...busMarkers,
    //   if (_showStops) ..._stopMarkers,
    // };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          IconButton(
            icon: Icon(_showStops ? Icons.place : Icons.place_outlined),
            onPressed: () {
              setState(() {
                _showStops = !_showStops;
              });
            },
            tooltip: _showStops ? 'Hide stops' : 'Show stops',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRouteData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _routeData == null
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
              : Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(6.9271, 79.8612), // Default to Colombo
                        zoom: 12.0,
                      ),
                      // markers: allMarkers,
                      polylines: _routePolylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController.complete(controller);
                        _fitMapToRoute();
                      },
                    ),

                    // Route details card
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.routeName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Text(
                                  //   // 'Active Buses: ${vehicleProvider.activeVehicles.length}',
                                  //   style:
                                  //       Theme.of(context).textTheme.bodyMedium,
                                  // ),
                                  Text(
                                    'Stops: ${_routeData?['stops']?.length ?? 0}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildLegendItem(
                                      Colors.green, 'Starting Point'),
                                  _buildLegendItem(Colors.red, 'Ending Point'),
                                  _buildLegendItem(
                                      Colors.deepPurple, 'Bus Stops'),
                                  _buildLegendItem(
                                      Colors.green.shade700, 'Active Buses'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // ElevatedButton(
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => BusListScreen(
                              //           routeId: widget.routeId,
                              //           routeName: widget.routeName,
                              //           // vehicles: vehicleProvider
                              //               .activeVehicles.values
                              //               .toList(),
                              //         ),
                              //       ),
                              //     );
                              //   },
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor:
                              //         Theme.of(context).colorScheme.primary,
                              //     foregroundColor:
                              //         Theme.of(context).colorScheme.onPrimary,
                              //   ),
                              //   child: const Text('View All Buses'),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class BusListScreen extends StatelessWidget {
  final String routeId;
  final String routeName;
  final List<dynamic> vehicles;

  const BusListScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
    required this.vehicles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buses on $routeName'),
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No active buses on this route'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final busNumber = vehicle['busNumber'] ?? 'Unknown';
                final status = vehicle['status'] ?? 'Unknown';
                final lastUpdated = vehicle['lastLocationUpdate'] != null
                    ? DateTime.parse(vehicle['lastLocationUpdate'])
                    : null;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.directions_bus,
                      color: status == 'active' ? Colors.green : Colors.grey,
                      size: 36,
                    ),
                    title: Text('Bus $busNumber'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${status.toUpperCase()}'),
                        if (lastUpdated != null)
                          Text(
                            'Last updated: ${_formatTimeAgo(lastUpdated)}',
                            style: TextStyle(
                              color: _getTimeColor(lastUpdated),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show bus details dialog
                      _showBusDetailsDialog(context, vehicle);
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Color _getTimeColor(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 5) {
      return Colors.green;
    } else if (difference.inMinutes < 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _showBusDetailsDialog(BuildContext context, dynamic vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bus ${vehicle['busNumber'] ?? 'Unknown'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Status', vehicle['status']?.toUpperCase() ?? 'Unknown'),
            _buildDetailRow('Model', vehicle['busModel'] ?? 'Unknown'),
            _buildDetailRow(
                'Capacity', '${vehicle['capacity'] ?? 'Unknown'} passengers'),
            _buildDetailRow('Driver', vehicle['driverName'] ?? 'Unknown'),
            _buildDetailRow(
                'License Plate', vehicle['licensePlate'] ?? 'Unknown'),
            if (vehicle['nextStop'] != null)
              _buildDetailRow(
                  'Next Stop', vehicle['nextStop']['name'] ?? 'Unknown'),
            if (vehicle['estimatedArrival'] != null)
              _buildDetailRow('ETA', '${vehicle['estimatedArrival']} min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
