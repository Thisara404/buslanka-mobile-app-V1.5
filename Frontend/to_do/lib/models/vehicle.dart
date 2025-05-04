// import 'package:google_maps_flutter/google_maps_flutter.dart';
// // Additional import for the getStatusColor method
// import 'package:flutter/material.dart';

// class Vehicle {
//   final String id;
//   final String busNumber;
//   final String? busModel;
//   final String? busColor;
//   final int? capacity;
//   final LatLng? currentLocation;
//   final String status;
//   final String? driverId;
//   final String? routeId;
//   final String? currentScheduleId;

//   Vehicle({
//     required this.id,
//     required this.busNumber,
//     this.busModel,
//     this.busColor,
//     this.capacity,
//     this.currentLocation,
//     this.status = 'inactive',
//     this.driverId,
//     this.routeId,
//     this.currentScheduleId,
//   });

//   factory Vehicle.fromJson(Map<String, dynamic> json) {
//     // Parse current location if available
//     LatLng? location;
//     if (json['currentLocation'] != null && 
//         json['currentLocation']['coordinates'] != null) {
//       final coordinates = json['currentLocation']['coordinates'];
//       location = LatLng(
//         coordinates[1].toDouble(), 
//         coordinates[0].toDouble()
//       );
//     }

//     return Vehicle(
//       id: json['_id'] ?? '',
//       busNumber: json['busNumber'] ?? 'Unknown',
//       busModel: json['busModel'],
//       busColor: json['busColor'],
//       capacity: json['capacity'],
//       currentLocation: location,
//       status: json['status'] ?? 'inactive',
//       driverId: json['driver'],
//       routeId: json['route'],
//       currentScheduleId: json['currentSchedule'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {
//       '_id': id,
//       'busNumber': busNumber,
//       'busModel': busModel,
//       'busColor': busColor,
//       'capacity': capacity,
//       'status': status,
//       'driver': driverId,
//       'route': routeId,
//       'currentSchedule': currentScheduleId,
//     };

//     if (currentLocation != null) {
//       data['currentLocation'] = {
//         'type': 'Point',
//         'coordinates': [currentLocation!.longitude, currentLocation!.latitude]
//       };
//     }
    
//     return data;
//   }

//   // Get status color
//   Color getStatusColor() {
//     switch (status) {
//       case 'active':
//         return Colors.green;
//       case 'maintenance':
//         return Colors.orange;
//       case 'inactive':
//       default:
//         return Colors.grey;
//     }
//   }

//   // Check if vehicle is currently in service
//   bool isInService() {
//     return status == 'active' && routeId != null && currentScheduleId != null;
//   }
// }

