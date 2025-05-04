import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:to_do/services/schedule_service.dart';
import 'package:intl/intl.dart';
import 'package:to_do/widgets/passenger/eta_display.dart';

class StopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stop;
  final String routeId;
  final String routeName;
  final int stopIndex;
  final int totalStops;

  const StopDetailsScreen({
    Key? key,
    required this.stop,
    required this.routeId,
    required this.routeName,
    required this.stopIndex,
    required this.totalStops,
  }) : super(key: key);

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get schedules for this route
      final schedules =
          await ScheduleService.getSchedulesByRoute(widget.routeId);

      // Find stop arrival times for each schedule
      List<Map<String, dynamic>> schedulesWithTimes = [];
      for (var schedule in schedules) {
        try {
          final scheduleDetails =
              await ScheduleService.getEstimatedArrivalTimes(schedule['_id']);
          final stopTimes = scheduleDetails['stopTimes'] ?? [];

          // Find the time for this specific stop
          final stopTime = stopTimes.firstWhere(
            (time) => time['stopId'] == widget.stop['_id'],
            orElse: () => {'arrivalTime': null, 'departureTime': null},
          );

          schedulesWithTimes.add({
            ...schedule,
            'arrivalTime': stopTime['arrivalTime'],
            'departureTime': stopTime['departureTime'],
          });
        } catch (e) {
          print('Error getting times for schedule ${schedule['_id']}: $e');
          schedulesWithTimes.add(schedule);
        }
      }

      setState(() {
        _schedules = schedulesWithTimes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedules: $e';
      });
      print('Error loading schedules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get stop coordinates for map
    LatLng? stopLocation;
    if (widget.stop['location'] != null &&
        widget.stop['location']['coordinates'] != null) {
      final coordinates = widget.stop['location']['coordinates'];
      stopLocation = LatLng(coordinates[1], coordinates[0]);
    }

    // Format stop position (e.g., "Stop 2 of 10")
    final stopPosition = 'Stop ${widget.stopIndex + 1} of ${widget.totalStops}';

    // Get stop name
    final stopName = widget.stop['name'] ?? 'Unknown Stop';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stop Details'),
      ),
      body: Column(
        children: [
          // Stop information header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stopPosition,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Route: ${widget.routeName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Map view of the stop
          if (stopLocation != null)
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: stopLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('stop_${widget.stop['_id']}'),
                      position: stopLocation,
                      infoWindow: InfoWindow(
                        title: stopName,
                        snippet: stopPosition,
                      ),
                    ),
                  },
                  liteModeEnabled: true,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                ),
              ),
            ),

          // Schedules
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSchedules,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _schedules.isEmpty
                        ? const Center(child: Text('No schedules available'))
                        : ListView.builder(
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _schedules[index];

                              // Format times
                              final timeFormat = DateFormat('HH:mm');
                              final arrivalTime = schedule['arrivalTime'] !=
                                      null
                                  ? timeFormat.format(
                                      DateTime.parse(schedule['arrivalTime']))
                                  : 'N/A';
                              final departureTime = schedule['departureTime'] !=
                                      null
                                  ? timeFormat.format(
                                      DateTime.parse(schedule['departureTime']))
                                  : 'N/A';

                              // Get status
                              final status = schedule['status'] ?? 'scheduled';

                              // Get days
                              final days = schedule['dayOfWeek'] as List?;
                              final daysText = days != null
                                  ? days.join(', ')
                                  : 'Unknown days';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Schedule #${index + 1}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Days: $daysText',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildTimeInfo('Arrival', arrivalTime,
                                              Icons.access_time),
                                          _buildTimeInfo(
                                              'Departure',
                                              departureTime,
                                              Icons.departure_board),
                                        ],
                                      ),

                                      // Show ETA for in-progress schedules
                                      if (status == 'in-progress' &&
                                          schedule['arrivalTime'] != null) ...[
                                        const Divider(height: 24),
                                        ETADisplay(
                                          estimatedArrival: DateTime.parse(
                                              schedule['arrivalTime']),
                                          scheduledArrival: schedule[
                                                      'scheduledArrivalTime'] !=
                                                  null
                                              ? DateTime.parse(schedule[
                                                  'scheduledArrivalTime'])
                                              : null,
                                          isLive: true,
                                          vehicleId: schedule['vehicleId']
                                              ?['_id'],
                                          busNumber: schedule['vehicleId']
                                              ?['busNumber'],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'in-progress':
        color = Colors.green;
        break;
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
