import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutePolyline {
  static Polyline create({
    required String id,
    required List<LatLng> points,
    Color color = Colors.blue,
    int width = 5,
    bool geodesic = true,
    JointType jointType = JointType.round,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: color,
      width: width,
      geodesic: geodesic,
      jointType: jointType,
    );
  }

  // Create a set of polylines for a route and its segments
  static Set<Polyline> createRoutePolylines(
    String routeId,
    List<LatLng> mainPathPoints,
    Map<String, List<LatLng>> segmentPoints,
  ) {
    final Set<Polyline> polylines = {};

    // Add main route polyline
    polylines.add(
      create(
        id: 'route_$routeId',
        points: mainPathPoints,
        color: Colors.blue,
        width: 5,
      ),
    );

    // Add segment polylines if provided
    segmentPoints.forEach((segmentId, points) {
      polylines.add(
        create(
          id: 'segment_${routeId}_$segmentId',
          points: points,
          color: Colors.green.withOpacity(0.7),
          width: 4,
        ),
      );
    });

    return polylines;
  }
}
