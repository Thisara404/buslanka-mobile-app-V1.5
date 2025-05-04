import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationType { userLocation, busStop, vehicle, destination, other }

class LocationModel {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  final LocationType type;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.type = LocationType.other,
  });

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
      'type': type.toString(),
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      name: json['name'],
      address: json['address'],
      type: _parseLocationType(json['type']),
    );
  }

  factory LocationModel.fromLatLng(LatLng latLng,
      {String? name, String? address, LocationType type = LocationType.other}) {
    return LocationModel(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      name: name,
      address: address,
      type: type,
    );
  }

  static LocationType _parseLocationType(String? typeString) {
    if (typeString == null) return LocationType.other;

    try {
      return LocationType.values.firstWhere(
        (type) => type.toString() == typeString,
        orElse: () => LocationType.other,
      );
    } catch (_) {
      return LocationType.other;
    }
  }
}
