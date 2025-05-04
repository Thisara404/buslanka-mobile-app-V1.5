import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/config/config.dart';

class RouteService {
  // Get all routes
  static Future<List<dynamic>> getAllRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to load routes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load routes: $e');
    }
  }

  // Get route by ID
  static Future<Map<String, dynamic>> getRouteById(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/$routeId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to load route: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load route: $e');
    }
  }

  // Get routes near location
  static Future<List<dynamic>> getRoutesNearLocation(
      double latitude, double longitude,
      {double maxDistance = 2000}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/nearby?latitude=$latitude&longitude=$longitude&maxDistance=$maxDistance'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to load nearby routes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load nearby routes: $e');
    }
  }

  // Search routes
  static Future<List<dynamic>> searchRoutes(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/search?keyword=$keyword'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to search routes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search routes: $e');
    }
  }

  // Get route directions
  static Future<Map<String, dynamic>> getRouteDirections(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/$routeId/directions'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to get route directions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get route directions: $e');
    }
  }

  // Get user favorites (requires auth)
  static Future<List<dynamic>> getFavoriteRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to load favorite routes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load favorite routes: $e');
    }
  }

  // Add route to favorites (requires auth)
  static Future<bool> addToFavorites(String routeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/favorites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'routeId': routeId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove route from favorites (requires auth)
  static Future<bool> removeFromFavorites(String routeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/favorites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'routeId': routeId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Create new route (requires auth)
  static Future<Map<String, dynamic>> createRoute(
      Map<String, dynamic> routeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(routeData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to create route: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  // Delete route (requires auth)
  static Future<bool> deleteRoute(String routeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.routesEndpoint}/$routeId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }
}
