import 'package:intl/intl.dart';

class StopTime {
  final String stopId;
  final String stopName;
  final DateTime? arrivalTime;
  final DateTime? departureTime;

  StopTime({
    required this.stopId,
    required this.stopName,
    this.arrivalTime,
    this.departureTime,
  });

  factory StopTime.fromJson(Map<String, dynamic> json) {
    return StopTime(
      stopId: json['stopId'] ?? '',
      stopName: json['stopName'] ?? 'Unnamed Stop',
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'])
          : null,
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'arrivalTime': arrivalTime?.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
    };
  }
}

class Schedule {
  final String id;
  final String routeId;
  // final String? vehicleId;
  final String? driverId;
  final List<String> dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<StopTime> stopTimes;
  final bool isRecurring;

  Schedule({
    required this.id,
    required this.routeId,
    // this.vehicleId,
    this.driverId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.status = 'scheduled',
    this.stopTimes = const [],
    this.isRecurring = true,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    // Parse days of week
    final daysOfWeek =
        (json['dayOfWeek'] as List?)?.map((day) => day.toString()).toList() ??
            [];

    // Parse stop times
    final stopTimesList = (json['stopTimes'] as List?)
            ?.map((stop) => StopTime.fromJson(stop))
            .toList() ??
        [];

    return Schedule(
      id: json['_id'] ?? '',
      routeId: json['routeId'] ?? '',
      // vehicleId: json['vehicleId'],
      driverId: json['driverId'],
      dayOfWeek: daysOfWeek,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? 'scheduled',
      stopTimes: stopTimesList,
      isRecurring: json['isRecurring'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'routeId': routeId,
      // 'vehicleId': vehicleId,
      'driverId': driverId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'stopTimes': stopTimes.map((stop) => stop.toJson()).toList(),
      'isRecurring': isRecurring,
    };
  }

  // Format start and end times for display
  String getTimeRangeFormatted() {
    final timeFormat = DateFormat('HH:mm');
    return '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}';
  }

  // Format days for display
  String getDaysFormatted() {
    if (dayOfWeek.isEmpty) return 'No days set';
    return dayOfWeek.join(', ');
  }

  // Check if schedule is active today
  bool isActiveToday() {
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    return dayOfWeek.contains(today);
  }

  // Get estimated arrival time for a specific stop
  DateTime? getEstimatedArrivalForStop(String stopId) {
    try {
      final stopTime = stopTimes.firstWhere((stop) => stop.stopId == stopId);
      return stopTime.arrivalTime;
    } catch (_) {
      return null;
    }
  }
}
