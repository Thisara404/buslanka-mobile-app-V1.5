import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleMarker {
  static Marker create({
    required String vehicleId,
    required LatLng position,
    required String busNumber,
    String? status,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId('vehicle_$vehicleId'),
      position: position,
      infoWindow: InfoWindow(
        title: 'Bus $busNumber',
        snippet: 'Status: ${status ?? 'Active'}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: onTap,
    );
  }

  static Marker fromVehicleData(Map<String, dynamic> vehicle) {
    if (vehicle['currentLocation'] == null ||
        vehicle['currentLocation']['coordinates'] == null) {
      throw ArgumentError(
          'Vehicle data must contain currentLocation with coordinates');
    }

    final coordinates = vehicle['currentLocation']['coordinates'];
    final vehicleId = vehicle['_id'];
    final busNumber = vehicle['busNumber'] ?? 'Unknown';
    final status = vehicle['status'] ?? 'Active';

    return create(
      vehicleId: vehicleId,
      position: LatLng(coordinates[1], coordinates[0]),
      busNumber: busNumber,
      status: status,
    );
  }

  static Set<Marker> createVehicleMarkers(List<Map<String, dynamic>> vehicles) {
    final Set<Marker> markers = {};

    for (final vehicle in vehicles) {
      try {
        final marker = fromVehicleData(vehicle);
        markers.add(marker);
      } catch (e) {
        print('Error creating marker for vehicle: $e');
      }
    }

    return markers;
  }
}
