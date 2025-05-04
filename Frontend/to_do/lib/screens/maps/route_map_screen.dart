import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/services/socket_service.dart';
import 'package:to_do/utils/map_utils.dart';

class RouteMapScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteMapScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
  }) : super(key: key);

  @override
  _RouteMapScreenState createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Map elements
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, dynamic>? _routeData;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    // Untrack route when leaving screen
    final vehicleProvider =
        // Provider.of<VehicleProvider>(context, listen: false);
    // vehicleProvider.untrackRoute(widget.routeId);
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize location
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();

      // Get route data
      _routeData = await RouteService.getRouteById(widget.routeId);

      // Process route data
      _processRouteData();

      // // Track this route in the vehicle provider
      // final vehicleProvider =
      //     Provider.of<VehicleProvider>(context, listen: false);
      // vehicleProvider.trackRoute(widget.routeId);

      // Connect to socket for real-time updates
      await SocketService.initSocket();
      SocketService.subscribeToRoute(widget.routeId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load map: $e';
      });
      print('Map initialization error: $e');
    }
  }

  void _processRouteData() {
    if (_routeData == null) return;

    // Add stop markers
    final stops = _routeData!['stops'] ?? [];
    _markers = MapUtils.stopsToMarkers(stops);

    // Add route polyline
    if (_routeData!['path'] != null &&
        _routeData!['path']['coordinates'] != null) {
      final coordinates = _routeData!['path']['coordinates'];
      List<LatLng> polylinePoints = [];

      for (var coordinate in coordinates) {
        polylinePoints.add(MapUtils.coordinatesToLatLng(coordinate));
      }

      _polylines = MapUtils.createPolylines(polylinePoints);
    }

    // Add user location marker if available
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: locationProvider.currentLatLng!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void _fitMapToRoute() async {
    if (_routeData == null || !_controller.isCompleted) return;

    List<LatLng> points = [];

    // Add all stops to points
    for (var stop in _routeData!['stops']) {
      final coordinates = stop['location']['coordinates'];
      points.add(MapUtils.coordinatesToLatLng(coordinates));
    }

    // Add all vehicles to points
    // final vehicleProvider =
    //     // Provider.of<VehicleProvider>(context, listen: false);
    // vehicleProvider.markers.forEach((marker) {
    //   points.add(marker.position);
    // });

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
    // Get markers from vehicle provider
    // final vehicleProvider = Provider.of<VehicleProvider>(context);
    // final allMarkers = {..._markers, ...vehicleProvider.markers};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fitMapToRoute,
            tooltip: 'Fit map to route',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target:
                        Provider.of<LocationProvider>(context).currentLatLng ??
                            const LatLng(6.9271, 79.8612), // Default to Colombo
                    zoom: 14.0,
                  ),
                  // markers: allMarkers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _fitMapToRoute();
                    });
                  },
                ),
    );
  }
}
