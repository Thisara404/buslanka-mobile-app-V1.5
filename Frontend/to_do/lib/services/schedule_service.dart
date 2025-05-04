import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/config/config.dart';
import 'package:to_do/services/api/schedule_api.dart';

class ScheduleService {
  // Get schedules by route
  static Future<List<dynamic>> getSchedulesByRoute(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}/route/$routeId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to load schedules: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load schedules: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverActiveSchedules() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('token');

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}/driver/active'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(
            responseData['data'].map((x) => Map<String, dynamic>.from(x)));
      } else {
        throw Exception('Failed to load active schedules: ${response.body}');
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch driver schedules: $e');
    }
  }

  // Get all schedules for a driver
  static Future<List<Map<String, dynamic>>> getSchedules(String? token) async {
    try {
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}/driver'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Convert to List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(
            responseData['data'].map((x) => Map<String, dynamic>.from(x)));
      } else {
        throw Exception('Failed to load schedules: ${response.body}');
      }
    } catch (e) {
      // For demo purposes, return mock data if API fails
      print('Error loading schedules, using mock data: $e');
      return _getMockSchedules();
    }
  }

  // Create a new schedule
  static Future<Map<String, dynamic>> createSchedule(
      String? token, Map<String, dynamic> scheduleData) async {
    try {
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(scheduleData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to create schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  // Update schedule status
  static Future<bool> updateScheduleStatus(
      String? token, String scheduleId, String status) async {
    try {
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response =
          await ScheduleApi.updateScheduleStatus(scheduleId, status);
      return response['status'] == true;
    } catch (e) {
      throw Exception('Failed to update schedule status: $e');
    }
  }

  // Get estimated arrival times for all stops in a schedule
  static Future<Map<String, dynamic>> getEstimatedArrivalTimes(
      String scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}/$scheduleId/arrivals'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception(
            'Failed to load estimated arrival times: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load estimated arrival times: $e');
    }
  }

  // Delete a schedule
  static Future<bool> deleteSchedule(String? token, String scheduleId) async {
    try {
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.schedulesEndpoint}/$scheduleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Helper method to get mock schedules data for demo purposes
  static List<Map<String, dynamic>> _getMockSchedules() {
    final now = DateTime.now();

    return [
      {
        'id': 'schedule-1',
        'routeId': 'route-101',
        'routeName': 'City Center - Airport',
        'startTime': now.add(const Duration(hours: 1)).toIso8601String(),
        'endTime': now.add(const Duration(hours: 5)).toIso8601String(),
        'status': 'scheduled',
        'notes': 'Regular route',
        'vehicleId': 'vehicle-001',
        'vehicleName': 'BUS-1234',
        'stops': [
          {'name': 'City Center', 'time': '08:00'},
          {'name': 'Central Station', 'time': '08:15'},
          {'name': 'Market Square', 'time': '08:30'},
          {'name': 'Hospital', 'time': '08:45'},
          {'name': 'University', 'time': '09:00'},
          {'name': 'Tech Park', 'time': '09:15'},
          {'name': 'Shopping Mall', 'time': '09:30'},
          {'name': 'Airport', 'time': '09:45'},
        ],
      },
      {
        'id': 'schedule-2',
        'routeId': 'route-102',
        'routeName': 'Downtown Loop',
        'startTime': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'endTime': now.add(const Duration(hours: 1)).toIso8601String(),
        'status': 'in-progress',
        'notes': 'High traffic expected around noon',
        'vehicleId': 'vehicle-001',
        'vehicleName': 'BUS-1234',
        'stops': [
          {'name': 'Main Station', 'time': '10:00'},
          {'name': 'City Hall', 'time': '10:15'},
          {'name': 'Central Park', 'time': '10:30'},
          {'name': 'Business District', 'time': '10:45'},
          {'name': 'Shopping Center', 'time': '11:00'},
          {'name': 'Main Station', 'time': '11:15'},
        ],
        'progress': 0.6,
        'currentStop': 'Business District',
        'nextStop': 'Shopping Center',
      },
      {
        'id': 'schedule-3',
        'routeId': 'route-103',
        'routeName': 'Beach Route',
        'startTime': now.subtract(const Duration(days: 1)).toIso8601String(),
        'endTime':
            now.subtract(const Duration(days: 1, hours: -4)).toIso8601String(),
        'status': 'completed',
        'notes': 'Weekend special route',
        'vehicleId': 'vehicle-001',
        'vehicleName': 'BUS-1234',
        'stops': [
          {'name': 'City Center', 'time': '09:00'},
          {'name': 'Suburb Station', 'time': '09:20'},
          {'name': 'Beachfront', 'time': '09:40'},
          {'name': 'Pier', 'time': '10:00'},
          {'name': 'Lighthouse', 'time': '10:20'},
          {'name': 'Beach Resort', 'time': '10:40'},
        ],
      },
      {
        'id': 'schedule-4',
        'routeId': 'route-101',
        'routeName': 'City Center - Airport',
        'startTime':
            now.add(const Duration(days: 1, hours: 2)).toIso8601String(),
        'endTime': now.add(const Duration(days: 1, hours: 6)).toIso8601String(),
        'status': 'scheduled',
        'notes': 'Morning peak hours',
        'vehicleId': 'vehicle-001',
        'vehicleName': 'BUS-1234',
        'stops': [
          {'name': 'City Center', 'time': '08:00'},
          {'name': 'Central Station', 'time': '08:15'},
          {'name': 'Market Square', 'time': '08:30'},
          {'name': 'Hospital', 'time': '08:45'},
          {'name': 'University', 'time': '09:00'},
          {'name': 'Tech Park', 'time': '09:15'},
          {'name': 'Shopping Mall', 'time': '09:30'},
          {'name': 'Airport', 'time': '09:45'},
        ],
      },
    ];
  }
}
