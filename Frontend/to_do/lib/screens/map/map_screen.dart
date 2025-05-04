import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/config/maps_config.dart';
import 'package:to_do/utils/map_utils.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final double initialZoom;
  final Set<Marker>? initialMarkers;
  final Set<Polyline>? initialPolylines;
  final bool showMyLocation;
  final bool trackVehicles;
  final Widget? bottomWidget;
  final Function(GoogleMapController)? onMapCreated;

  const MapScreen({
    Key? key,
    this.initialPosition,
    this.initialZoom = MapsConfig.defaultZoom,
    this.initialMarkers,
    this.initialPolylines,
    this.showMyLocation = true,
    this.trackVehicles = false,
    this.bottomWidget,
    this.onMapCreated,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _mapStyle = '[]'; // Default empty style

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize location if showing my location
      if (widget.showMyLocation) {
        final locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        await locationProvider.getCurrentLocation();
      }

      // Load map style based on theme
      final isDarkMode = await MapUtils.isDarkModeEnabled();
      _mapStyle =
          isDarkMode ? MapsConfig.nightMapStyle : MapsConfig.dayMapStyle;

      // Initialize markers
      if (widget.initialMarkers != null) {
        _markers = widget.initialMarkers!;
      }

      // Initialize polylines
      if (widget.initialPolylines != null) {
        _polylines = widget.initialPolylines!;
      }

      // // Start vehicle tracking if needed
      // if (widget.trackVehicles) {
      //   final vehicleProvider =
      //       Provider.of<VehicleProvider>(context, listen: false);
      //   vehicleProvider.startTracking();
      // }

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

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      // Set map style
      await controller.setMapStyle(_mapStyle);

      // Complete the controller
      _controller.complete(controller);

      // Call custom onMapCreated callback if provided
      if (widget.onMapCreated != null) {
        widget.onMapCreated!(controller);
      }
    } catch (e) {
      print('Error setting map style: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      if (locationProvider.currentLatLng == null) {
        await locationProvider.getCurrentLocation();
      }

      if (locationProvider.currentLatLng != null) {
        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            locationProvider.currentLatLng!,
            MapsConfig.closeZoom,
          ),
        );
      }
    } catch (e) {
      print('Error going to current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current location from provider
    final locationProvider = Provider.of<LocationProvider>(context);
    final currentLatLng = locationProvider.currentLatLng;

    // // For vehicle tracking
    // Set<Marker> allMarkers = {..._markers};
    // if (widget.trackVehicles) {
    //   final vehicleProvider = Provider.of<VehicleProvider>(context);
    //   allMarkers = {...allMarkers, ...vehicleProvider.markers};
    // }

    // Initial camera position
    final initialPosition =
        widget.initialPosition ?? currentLatLng ?? MapsConfig.defaultCenter;

    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading map...')
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initialize,
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
                        target: initialPosition,
                        zoom: widget.initialZoom,
                      ),
                      // markers: allMarkers,
                      polylines: _polylines,
                      myLocationEnabled: widget.showMyLocation,
                      myLocationButtonEnabled: false,
                      onMapCreated: _onMapCreated,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                    ),

                    // My location button
                    if (widget.showMyLocation)
                      Positioned(
                        right: 16,
                        bottom: widget.bottomWidget != null ? 120 : 16,
                        child: FloatingActionButton(
                          heroTag: "locationBtn",
                          onPressed: _goToMyLocation,
                          child: const Icon(Icons.my_location),
                          mini: true,
                        ),
                      ),

                    // Bottom widget if provided
                    if (widget.bottomWidget != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: widget.bottomWidget!,
                      ),
                  ],
                ),
    );
  }
}
