import 'package:to_do/services/api/api_client.dart';
import 'package:to_do/config/config.dart';

class RouteApi {
  // Get all routes
  static Future<Map<String, dynamic>> getAllRoutes() async {
    try {
      return await ApiClient.get(ApiConfig.routesEndpoint);
    } catch (e) {
      throw Exception('Failed to get routes: ${e.toString()}');
    }
  }

  // Get route by ID
  static Future<Map<String, dynamic>> getRouteById(String routeId) async {
    try {
      return await ApiClient.get('${ApiConfig.routesEndpoint}/$routeId');
    } catch (e) {
      throw Exception('Failed to get route details: ${e.toString()}');
    }
  }

  // Get routes near location
  static Future<Map<String, dynamic>> getRoutesNearLocation(
      double latitude, double longitude,
      {double maxDistance = 2000}) async {
    try {
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'distance': maxDistance.toString(),
      };

      return await ApiClient.get(
        ApiConfig.nearbyRoutesEndpoint,
        queryParams: queryParams,
      );
    } catch (e) {
      throw Exception('Failed to get nearby routes: ${e.toString()}');
    }
  }

  // Search routes by keyword
  static Future<Map<String, dynamic>> searchRoutes(String keyword) async {
    try {
      final queryParams = {
        'q': keyword,
      };

      return await ApiClient.get(
        ApiConfig.searchRoutesEndpoint,
        queryParams: queryParams,
      );
    } catch (e) {
      throw Exception('Failed to search routes: ${e.toString()}');
    }
  }

  // Get route directions
  static Future<Map<String, dynamic>> getRouteDirections(String routeId) async {
    try {
      return await ApiClient.get(
          '${ApiConfig.routeDirectionsEndpoint}/$routeId/directions');
    } catch (e) {
      throw Exception('Failed to get route directions: ${e.toString()}');
    }
  }

  // Get favorite routes
  static Future<Map<String, dynamic>> getFavoriteRoutes() async {
    try {
      return await ApiClient.get(ApiConfig.userFavoritesEndpoint,
          requiresAuth: true);
    } catch (e) {
      throw Exception('Failed to get favorite routes: ${e.toString()}');
    }
  }

  // Add route to favorites
  static Future<Map<String, dynamic>> addToFavorites(String routeId) async {
    try {
      return await ApiClient.post(
        ApiConfig.userFavoritesEndpoint,
        body: {'routeId': routeId},
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to add route to favorites: ${e.toString()}');
    }
  }

  // Remove route from favorites
  static Future<Map<String, dynamic>> removeFromFavorites(
      String routeId) async {
    try {
      return await ApiClient.delete(
        '${ApiConfig.userFavoritesEndpoint}/$routeId',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to remove route from favorites: ${e.toString()}');
    }
  }

  // Geocode address to coordinates
  static Future<Map<String, dynamic>> geocodeAddress(String address) async {
    try {
      final queryParams = {
        'address': address,
      };

      return await ApiClient.get(
        ApiConfig.geocodeEndpoint,
        queryParams: queryParams,
      );
    } catch (e) {
      throw Exception('Failed to geocode address: ${e.toString()}');
    }
  }
}
