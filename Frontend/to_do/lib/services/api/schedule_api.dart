import 'package:to_do/services/api/api_client.dart';
import 'package:to_do/config/config.dart';

class ScheduleApi {
  // Get all schedules
  static Future<Map<String, dynamic>> getAllSchedules() async {
    try {
      return await ApiClient.get(ApiConfig.schedulesEndpoint,
          requiresAuth: true);
    } catch (e) {
      throw Exception('Failed to get schedules: ${e.toString()}');
    }
  }

  // Get schedule by ID
  static Future<Map<String, dynamic>> getScheduleById(String scheduleId) async {
    try {
      return await ApiClient.get(
        '${ApiConfig.schedulesEndpoint}/$scheduleId',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to get schedule details: ${e.toString()}');
    }
  }

  // Get schedules by route
  static Future<Map<String, dynamic>> getSchedulesByRoute(
      String routeId) async {
    try {
      return await ApiClient.get(
        '${ApiConfig.scheduleByRouteEndpoint}/$routeId',
      );
    } catch (e) {
      throw Exception('Failed to get schedules for route: ${e.toString()}');
    }
  }

  // Get estimated arrival times for all stops in a schedule
  static Future<Map<String, dynamic>> getEstimatedArrivalTimes(
      String scheduleId) async {
    try {
      return await ApiClient.get(
        '${ApiConfig.scheduleArrivalTimesEndpoint}/$scheduleId/stop-times',
      );
    } catch (e) {
      throw Exception('Failed to get estimated arrival times: ${e.toString()}');
    }
  }

  // Get estimated arrival time for a specific stop
  static Future<Map<String, dynamic>> getEstimatedArrivalTimeForStop(
    String scheduleId,
    String stopId,
  ) async {
    try {
      return await ApiClient.get(
        '${ApiConfig.scheduleArrivalTimesEndpoint}/$scheduleId/stop-times/$stopId',
      );
    } catch (e) {
      throw Exception('Failed to get estimated arrival time: ${e.toString()}');
    }
  }

  // Create a new schedule (driver/admin only)
  static Future<Map<String, dynamic>> createSchedule(
      Map<String, dynamic> scheduleData) async {
    try {
      return await ApiClient.post(
        ApiConfig.schedulesEndpoint,
        body: scheduleData,
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to create schedule: ${e.toString()}');
    }
  }

  // Update schedule status (driver only)
  static Future<Map<String, dynamic>> updateScheduleStatus(
    String scheduleId,
    String status,
  ) async {
    try {
      return await ApiClient.put(
        '${ApiConfig.schedulesEndpoint}/$scheduleId/status',
        body: {'status': status},
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to update schedule status: ${e.toString()}');
    }
  }

  // Delete a schedule (admin only)
  static Future<Map<String, dynamic>> deleteSchedule(String scheduleId) async {
    try {
      return await ApiClient.delete(
        '${ApiConfig.schedulesEndpoint}/$scheduleId',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete schedule: ${e.toString()}');
    }
  }

  // Get active schedules for driver
  static Future<Map<String, dynamic>> getDriverActiveSchedules() async {
    try {
      return await ApiClient.get(
        '${ApiConfig.schedulesEndpoint}/driver/active',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to get active schedules: ${e.toString()}');
    }
  }
}
