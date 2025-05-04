import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:to_do/models/route.dart';
import 'package:to_do/models/schedule.dart';
import 'package:to_do/models/vehicle.dart';
import 'package:to_do/config/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class OfflineService {
  static const String _cacheKeyRoutes = 'cached_routes';
  static const String _cacheKeySchedules = 'cached_schedules';
  static const String _cacheKeyVehicles = 'cached_vehicles';
  static const String _cacheDateKey = 'cache_timestamp';
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static bool _isOnline = true;

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static void startMonitoringConnectivity(
      Function(bool) onConnectivityChanged) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      // If coming back online and we were offline
      if (_isOnline && wasOffline) {
        onConnectivityChanged(true);
      } else if (!_isOnline) {
        onConnectivityChanged(false);
      }
    });
  }

  static void stopMonitoringConnectivity() {
    _connectivitySubscription?.cancel();
  }

  // Cache routes data locally
  static Future<bool> cacheRoutes(List<dynamic> routes) async {
    try {
      if (routes.length > AppConfig.maxCachedRoutes) {
        routes = routes.sublist(0, AppConfig.maxCachedRoutes);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyRoutes, jsonEncode(routes));
      await _updateCacheTimestamp();
      return true;
    } catch (e) {
      print('Error caching routes: $e');
      return false;
    }
  }

  // Get cached routes
  static Future<List<dynamic>> getCachedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKeyRoutes);
      if (cachedData == null) return [];
      return jsonDecode(cachedData);
    } catch (e) {
      print('Error retrieving cached routes: $e');
      return [];
    }
  }

  // Cache schedules data locally
  static Future<bool> cacheSchedules(List<dynamic> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeySchedules, jsonEncode(schedules));
      await _updateCacheTimestamp();
      return true;
    } catch (e) {
      print('Error caching schedules: $e');
      return false;
    }
  }

  // Get cached schedules
  static Future<List<dynamic>> getCachedSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKeySchedules);
      if (cachedData == null) return [];
      return jsonDecode(cachedData);
    } catch (e) {
      print('Error retrieving cached schedules: $e');
      return [];
    }
  }

  // Cache vehicles data locally
  static Future<bool> cacheVehicles(List<dynamic> vehicles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyVehicles, jsonEncode(vehicles));
      await _updateCacheTimestamp();
      return true;
    } catch (e) {
      print('Error caching vehicles: $e');
      return false;
    }
  }

  // Get cached vehicles
  static Future<List<dynamic>> getCachedVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKeyVehicles);
      if (cachedData == null) return [];
      return jsonDecode(cachedData);
    } catch (e) {
      print('Error retrieving cached vehicles: $e');
      return [];
    }
  }

  // Update timestamp when cache is updated
  static Future<void> _updateCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_cacheDateKey, now);
  }

  // Check if cache is expired (older than 24 hours)
  static Future<bool> isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheDateKey);
      if (timestampStr == null) return true;

      final cacheDate = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(cacheDate);

      // Cache expires after 24 hours
      return difference.inHours > 24;
    } catch (e) {
      return true;
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyRoutes);
      await prefs.remove(_cacheKeySchedules);
      await prefs.remove(_cacheKeyVehicles);
      await prefs.remove(_cacheDateKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
