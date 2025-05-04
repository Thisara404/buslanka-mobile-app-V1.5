import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StopMarker {
  static Marker create({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
    required BitmapDescriptor icon,
    double markerHue = BitmapDescriptor.hueRed,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon,
      onTap: onTap,
    );
  }

  // Create a marker for a bus stop
  static Marker createStopMarker({
    required String stopId,
    required LatLng position,
    required String name,
    String? arrivalTime,
    bool isNextStop = false,
    VoidCallback? onTap,
  }) {
    final hue =
        isNextStop ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed;
    final snippet = arrivalTime != null ? 'Arrival: $arrivalTime' : 'Bus stop';

    return create(
      id: 'stop_$stopId',
      position: position,
      title: name,
      snippet: snippet,
      markerHue: hue,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      onTap: onTap,
    );
  }

  // Create markers for multiple stops
  static Set<Marker> createStopMarkers({
    required List<Map<String, dynamic>> stops,
    String? nextStopId,
    Map<String, String>? arrivalTimes,
    Function(String)? onStopTap,
  }) {
    final Set<Marker> markers = {};

    for (final stop in stops) {
      final stopId = stop['_id'].toString();
      final isNextStop = nextStopId == stopId;
      final position = LatLng(
        stop['location']['coordinates'][1],
        stop['location']['coordinates'][0],
      );

      markers.add(
        createStopMarker(
          stopId: stopId,
          position: position,
          name: stop['name'] ?? 'Bus Stop',
          arrivalTime: arrivalTimes != null ? arrivalTimes[stopId] : null,
          isNextStop: isNextStop,
          onTap: onStopTap != null ? () => onStopTap(stopId) : null,
        ),
      );
    }

    return markers;
  }
}
