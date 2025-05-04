// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:to_do/config/config.dart';

// class VehicleService {
//   // Get all vehicles
//   static Future<List<dynamic>> getAllVehicles() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.vehiclesEndpoint}'),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return responseData['data'];
//       } else {
//         throw Exception('Failed to load vehicles: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load vehicles: $e');
//     }
//   }

//   // Get vehicle by ID
//   static Future<Map<String, dynamic>> getVehicleById(String vehicleId) async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             '${ApiConfig.baseUrl}${ApiConfig.vehiclesEndpoint}/$vehicleId'),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return responseData['data'];
//       } else {
//         throw Exception('Failed to load vehicle: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load vehicle: $e');
//     }
//   }

//   // Update vehicle location (requires auth)
//   static Future<bool> updateVehicleLocation(
//       String vehicleId, double latitude, double longitude) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString(ApiConfig.tokenKey);

//       if (token == null) {
//         throw Exception('Authentication required');
//       }

//       final response = await http.put(
//         Uri.parse(
//             '${ApiConfig.baseUrl}${ApiConfig.vehiclesEndpoint}/$vehicleId/location'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({
//           'longitude': longitude, // Changed order to match backend expectation
//           'latitude': latitude, // Backend expects longitude first
//           // Add additional metadata that might be helpful
//           'accuracy': 10.0, // Default accuracy in meters
//           'timestamp': DateTime.now().toIso8601String()
//         }),
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else if (response.statusCode == 403) {
//         print(
//             'Authorization error updating vehicle location: ${response.body}');
//         // Try to refresh token or notify user about permission issue
//         return false;
//       } else {
//         print(
//             'Error updating vehicle location: ${response.statusCode} - ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print('Exception updating vehicle location: $e');
//       throw Exception('Failed to update vehicle location: $e');
//     }
//   }

//   // Update vehicle status (requires auth)
//   static Future<bool> updateVehicleStatus(
//       String vehicleId, String status) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString(ApiConfig.tokenKey);

//       if (token == null) {
//         throw Exception('Authentication required');
//       }

//       final response = await http.put(
//         Uri.parse(
//             '${ApiConfig.baseUrl}${ApiConfig.vehiclesEndpoint}/$vehicleId/status'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({
//           'status': status,
//         }),
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       throw Exception('Failed to update vehicle status: $e');
//     }
//   }

//   // Get vehicles by route
//   static Future<List<dynamic>> getVehiclesByRoute(String routeId) async {
//     try {
//       final route = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/$routeId'),
//       );

//       if (route.statusCode == 200) {
//         final routeData = json.decode(route.body)['data'];
//         return routeData['vehicles'] ?? [];
//       } else {
//         throw Exception('Failed to load route vehicles: ${route.body}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load route vehicles: $e');
//     }
//   }
// }
