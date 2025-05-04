import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/services/route_service.dart';

class NearbyBusesScreen extends StatefulWidget {
  const NearbyBusesScreen({Key? key}) : super(key: key);

  @override
  _NearbyBusesScreenState createState() => _NearbyBusesScreenState();
}

class _NearbyBusesScreenState extends State<NearbyBusesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  double _radius = 2000; // 2km radius
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize location provider
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();

      // // Initialize vehicle provider
      // final vehicleProvider =
      //     Provider.of<VehicleProvider>(context, listen: false);
      // vehicleProvider.startTracking();

      await _loadNearbyVehicles();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize map: $e';
      });
      print('Map initialization error: $e');
    }
  }

  Future<void> _loadNearbyVehicles() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentLatLng = locationProvider.currentLatLng;

    if (currentLatLng == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get nearby routes
      final nearbyRoutes = await RouteService.getRoutesNearLocation(
        currentLatLng.latitude,
        currentLatLng.longitude,
        maxDistance: _radius,
      );

      // // Track these routes in the vehicle provider
      // final vehicleProvider =
      //     Provider.of<VehicleProvider>(context, listen: false);

      // for (var route in nearbyRoutes) {
      //   if (route['_id'] != null) {
      //     vehicleProvider.trackRoute(route['_id']);
      //   }
      // }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load nearby vehicles: $e';
      });
      print('Error loading nearby vehicles: $e');
    }
  }

  void _changeRadius(double value) {
    setState(() {
      _radius = value;
    });
    _loadNearbyVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    // final vehicleProvider = Provider.of<VehicleProvider>(context);
    final currentLatLng = locationProvider.currentLatLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyVehicles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: currentLatLng ?? const LatLng(6.9271, 79.8612),
                        zoom: 15.0,
                      ),
                      // markers: vehicleProvider.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
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
                                'Search Radius: ${(_radius / 1000).toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Slider(
                                value: _radius,
                                min: 500,
                                max: 5000,
                                divisions: 9,
                                label:
                                    '${(_radius / 1000).toStringAsFixed(1)} km',
                                onChanged: _changeRadius,
                              ),
                              // Text(
                              //   'Found: ${vehicleProvider.activeVehicles.length} active buses nearby',
                              //   style: Theme.of(context).textTheme.bodyMedium,
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
}
