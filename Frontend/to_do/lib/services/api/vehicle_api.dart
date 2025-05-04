// import 'package:to_do/services/api/api_client.dart';
// import 'package:to_do/config/config.dart';

// class VehicleApi {
//   // Get all vehicles
//   static Future<Map<String, dynamic>> getAllVehicles() async {
//     try {
//       return await ApiClient.get(ApiConfig.vehiclesEndpoint);
//     } catch (e) {
//       throw Exception('Failed to get vehicles: ${e.toString()}');
//     }
//   }

//   // Get vehicle by ID
//   static Future<Map<String, dynamic>> getVehicleById(String vehicleId) async {
//     try {
//       return await ApiClient.get('${ApiConfig.vehiclesEndpoint}/$vehicleId');
//     } catch (e) {
//       throw Exception('Failed to get vehicle details: ${e.toString()}');
//     }
//   }

//   // Get vehicles by route
//   static Future<Map<String, dynamic>> getVehiclesByRoute(String routeId) async {
//     try {
//       return await ApiClient.get(
//           '${ApiConfig.vehiclesByRouteEndpoint}/$routeId');
//     } catch (e) {
//       throw Exception('Failed to get vehicles for route: ${e.toString()}');
//     }
//   }

//   // Update vehicle location (driver only)
//   static Future<Map<String, dynamic>> updateVehicleLocation(
//     String vehicleId,
//     double latitude,
//     double longitude,
//   ) async {
//     try {
//       return await ApiClient.put(
//         '${ApiConfig.vehicleLocationEndpoint}/$vehicleId/location',
//         body: {
//           'location': {
//             'type': 'Point',
//             'coordinates': [longitude, latitude],
//           }
//         },
//         requiresAuth: true,
//       );
//     } catch (e) {
//       throw Exception('Failed to update vehicle location: ${e.toString()}');
//     }
//   }

//   // Update vehicle status (driver only)
//   static Future<Map<String, dynamic>> updateVehicleStatus(
//     String vehicleId,
//     String status,
//   ) async {
//     try {
//       return await ApiClient.put(
//         '${ApiConfig.vehicleStatusEndpoint}/$vehicleId/status',
//         body: {'status': status},
//         requiresAuth: true,
//       );
//     } catch (e) {
//       throw Exception('Failed to update vehicle status: ${e.toString()}');
//     }
//   }

//   // Get driver's vehicle (driver only)
//   static Future<Map<String, dynamic>> getDriverVehicle() async {
//     try {
//       return await ApiClient.get(
//         '${ApiConfig.vehiclesEndpoint}/driver',
//         requiresAuth: true,
//       );
//     } catch (e) {
//       throw Exception('Failed to get driver vehicle: ${e.toString()}');
//     }
//   }

//   // Get active vehicles near location
//   static Future<Map<String, dynamic>> getActiveVehiclesNearLocation(
//       double latitude, double longitude,
//       {double maxDistance = 2000}) async {
//     try {
//       return await ApiClient.get(
//         '${ApiConfig.vehiclesEndpoint}/nearby',
//         queryParams: {
//           'lat': latitude,
//           'lng': longitude,
//           'maxDistance': maxDistance,
//         },
//       );
//     } catch (e) {
//       throw Exception('Failed to get nearby vehicles: ${e.toString()}');
//     }
//   }
// }
