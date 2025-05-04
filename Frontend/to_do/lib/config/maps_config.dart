import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsConfig {
  // Default center of the map (Colombo, Sri Lanka)
  static const LatLng defaultCenter = LatLng(6.9271, 79.8612);

  // Default zoom level
  static const double defaultZoom = 15.0;
  static const double closeZoom = 18.0;
  static const double farZoom = 12.0;

  // Map styles
  static const String dayMapStyle = '[]'; // Default style
  static const String nightMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1b1b1b"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3d3d3d"
          }
        ]
      }
    ]
  ''';

  // Map configuration options
  static const Map<String, dynamic> mapOptions = {
    'zoomControlsEnabled': false,
    'mapType': MapType.normal,
    'myLocationEnabled': true,
    'myLocationButtonEnabled': true,
    'compassEnabled': true,
    'trafficEnabled': false,
    'indoorViewEnabled': false,
    'buildingsEnabled': true,
    'rotateGesturesEnabled': true,
    'scrollGesturesEnabled': true,
    'tiltGesturesEnabled': true,
    'zoomGesturesEnabled': true,
  };

  // Marker colors
  static const double userLocationMarkerHue = BitmapDescriptor.hueAzure;
  static const double vehicleMarkerHue = BitmapDescriptor.hueGreen;
  static const double stopMarkerHue = BitmapDescriptor.hueRed;
  static const double nextStopMarkerHue = BitmapDescriptor.hueOrange;

  // Polyline colors
  static const int routePolylineColor = 0xFF3388FF;
  static const int activeSegmentPolylineColor = 0xFF00AA00;

  // Geofencing settings
  static const double stopGeofenceRadiusMeters = 100.0;
  static const double routeGeofenceWidthMeters = 50.0;
}
