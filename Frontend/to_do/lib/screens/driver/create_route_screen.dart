import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/routes.dart';
import 'package:to_do/services/maps_service.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/utils/map_utils.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({Key? key}) : super(key: key);

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _endLocationController = TextEditingController();
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _routeDescriptionController = TextEditingController();
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _stops = [];
  List<List<double>> _pathCoordinates = [];
  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _isLoading = false;
  bool _routeGenerated = false;
  double _distance = 0;
  int _duration = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _routeNameController.dispose();
    _routeDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await MapsService.geocodeAddress(query);
      final Map<String, dynamic> resultMap = result as Map<String, dynamic>;
      final location = LatLng(
        resultMap['location']['coordinates'][1],
        resultMap['location']['coordinates'][0],
      );

      if (isStart) {
        _startLocation = location;
        _addMarker(location, 'start', 'Start Location', BitmapDescriptor.hueGreen);
      } else {
        _endLocation = location;
        _addMarker(location, 'end', 'End Location', BitmapDescriptor.hueRed);
      }

      // If both locations are set, center map to show both
      if (_startLocation != null && _endLocation != null) {
        _fitBothLocations();
      } else {
        // Center on the selected location
        _centerOnLocation(location);
      }

      setState(() {
        _isLoading = false;
        _routeGenerated = false; // Reset route when changing locations
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to find location: $e';
      });
    }
  }

  void _addMarker(LatLng position, String id, String title, double hue) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    );

    setState(() {
      _markers = _markers.where((m) => m.markerId.value != id).toSet();
      _markers.add(marker);
    });
  }

  Future<void> _centerOnLocation(LatLng location) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 14));
  }

  Future<void> _fitBothLocations() async {
    if (_startLocation == null || _endLocation == null) return;

    final GoogleMapController controller = await _mapController.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _startLocation!.latitude < _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude,
        _startLocation!.longitude < _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude,
      ),
      northeast: LatLng(
        _startLocation!.latitude > _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude,
        _startLocation!.longitude > _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude,
      ),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> _generateRoute() async {
    if (_startLocation == null || _endLocation == null) {
      setState(() {
        _errorMessage = 'Please select both start and end locations';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request directions from the backend
      final result = await MapsService.getDirections(_startLocation!, _endLocation!);
      
      // Process the polyline
      final polylinePoints = result['directions']['path']['coordinates']
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList()
          .cast<LatLng>();
      
      // Create polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      );

      // Extract and store path coordinates
      _pathCoordinates = result['directions']['path']['coordinates']
          .map<List<double>>((coord) => [coord[0], coord[1]])
          .toList()
          .cast<List<double>>();
      
      // Create stops from the path
      _stops = [
        {
          'name': 'Start Location',
          'location': {
            'type': 'Point',
            'coordinates': [_startLocation!.longitude, _startLocation!.latitude]
          }
        },
        {
          'name': 'End Location',
          'location': {
            'type': 'Point',
            'coordinates': [_endLocation!.longitude, _endLocation!.latitude]
          }
        }
      ];
      
      // Store additional data
      _distance = result['directions']['distance'] / 1000; // Convert to km
      _duration = (result['directions']['duration'] / 60).round(); // Convert to minutes
      
      setState(() {
        _polylines = {polyline};
        _isLoading = false;
        _routeGenerated = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate route: $e';
      });
    }
  }

  Future<void> _saveRoute() async {
    if (!_routeGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a route first')),
      );
      return;
    }

    if (_routeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a route name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create route data object
      final routeData = {
        'name': _routeNameController.text,
        'description': _routeDescriptionController.text,
        'stops': _stops,
        'path': {
          'type': 'LineString',
          'coordinates': _pathCoordinates
        },
        'distance': _distance,
        'estimatedDuration': _duration
      };

      // Call API to save route
      await RouteService.createRoute(routeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route created successfully')),
      );

      Navigator.pop(context, true); // Return to previous screen with success result
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save route: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Route'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search inputs
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _startLocationController,
                      decoration: InputDecoration(
                        labelText: 'Start Location',
                        hintText: 'Enter starting point',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _searchLocation(_startLocationController.text, true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _endLocationController,
                      decoration: InputDecoration(
                        labelText: 'End Location',
                        hintText: 'Enter destination',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _searchLocation(_endLocationController.text, false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Map view
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: locationProvider.currentLatLng ?? const LatLng(6.9271, 79.8612), // Default to Colombo
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  onTap: (LatLng position) {
                    // Allow tapping to select locations
                    if (_startLocation == null) {
                      _startLocation = position;
                      _addMarker(position, 'start', 'Start Location', BitmapDescriptor.hueGreen);
                      _startLocationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                    } else if (_endLocation == null) {
                      _endLocation = position;
                      _addMarker(position, 'end', 'End Location', BitmapDescriptor.hueRed);
                      _endLocationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                      _fitBothLocations();
                    }
                  },
                ),
              ),
              
              // Action buttons and route info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Error message
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Route info
                    if (_routeGenerated) ...[
                      Text(
                        'Distance: ${_distance.toStringAsFixed(2)} km • Duration: $_duration min',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Route name and description
                      TextField(
                        controller: _routeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Route Name*',
                          hintText: 'Enter a name for this route',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _routeDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter route description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveRoute,
                          icon: const Icon(Icons.save),
                          label: const Text('SAVE ROUTE'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startLocation != null && _endLocation != null
                              ? _generateRoute
                              : null,
                          icon: const Icon(Icons.route),
                          label: const Text('GENERATE ROUTE'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.createRoute);
                        },
                        icon: const Icon(Icons.add_road),
                        label: const Text('CREATE NEW ROUTE'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: LoadingIndicator(message: 'Processing...'),
            ),
        ],
      ),
    );
  }
}