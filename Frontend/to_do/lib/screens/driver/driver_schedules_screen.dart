import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/screens/driver/start_route_screen.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/services/schedule_service.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:to_do/screens/driver/driver_map_screen.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';

// Route names for navigation
class DriverRoutes {
  static const String driverHome = '/driver_home';
  static const String driverProfile = '/driver_profile';
  static const String driverSchedules = '/driver_schedules';
  static const String driverMap = '/driver_map';
  static const String settings = '/settings';
}

class DriverSchedulesScreen extends StatefulWidget {
  const DriverSchedulesScreen({Key? key}) : super(key: key);

  @override
  State<DriverSchedulesScreen> createState() => _DriverSchedulesScreenState();
}

class _DriverSchedulesScreenState extends State<DriverSchedulesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _schedules = [];
  late TabController _tabController;

  // Filter settings
  String _statusFilter = 'all';
  DateTime? _selectedDate;

  // New schedule creation
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDate = DateTime.now();
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _routeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the ScheduleApi to fetch schedules from the backend
      final response = await ScheduleService.getDriverActiveSchedules();

      setState(() {
        _schedules = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedules: $e';
      });

      // If API call fails, show mock data for development
      if (mounted) {
        setState(() {
          _schedules = [
            {
              'id': 'schedule-1',
              'routeId': 'route-101',
              'routeName': 'City Center - Airport',
              'startTime': DateTime.now()
                  .add(const Duration(hours: 1))
                  .toIso8601String(),
              'endTime': DateTime.now()
                  .add(const Duration(hours: 5))
                  .toIso8601String(),
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
            // Add other mock schedules as needed
          ];
          _errorMessage = null;
          _isLoading = false;
        });
      }

      print('Error loading schedules: $e');
    }
  }

  Future<void> _createNewSchedule() async {
    if (_startTime == null ||
        _endTime == null ||
        _routeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user token from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      // Extract route ID from controller text (format assumed to be "RouteName (ID)")
      final routeIdMatch =
          RegExp(r'\((.*?)\)$').firstMatch(_routeController.text);
      final routeId =
          routeIdMatch?.group(1) ?? 'route-101'; // Fallback for demo

      // Prepare schedule data
      final scheduleData = {
        'routeId': routeId,
        'dayOfWeek': [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday'
        ], // Default weekdays
        'startTime': _startTime!.toIso8601String(),
        'endTime': _endTime!.toIso8601String(),
        'notes': _notesController.text,
        'isRecurring': true
      };

      // Call the API to create a new schedule
      final result = await ScheduleService.createSchedule(token, scheduleData);

      // Reload schedules to show the new one
      await _loadSchedules();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create schedule: $e')),
      );

      // For demo purposes, add a mock schedule if API fails
      final newSchedule = {
        'id': 'schedule-${_schedules.length + 1}',
        'routeId': 'route-101',
        'routeName': _routeController.text,
        'startTime': _startTime!.toIso8601String(),
        'endTime': _endTime!.toIso8601String(),
        'status': 'scheduled',
        'notes': _notesController.text,
        'vehicleId': 'vehicle-001',
        'vehicleName': 'BUS-1234',
        'stops': [
          {
            'name': 'City Center',
            'time': DateFormat('HH:mm').format(_startTime!)
          },
          {'name': 'Airport', 'time': DateFormat('HH:mm').format(_endTime!)},
        ],
      };

      setState(() {
        _schedules.add(newSchedule);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _showRouteSelectionDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await RouteService.getAllRoutes();
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Route'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return ListTile(
                  title: Text(route['name'] ?? 'Unnamed Route'),
                  subtitle: Text(
                    route['description'] ?? 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _routeController.text =
                        "${route['name']} (${route['_id']})";
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load routes: $e')),
      );
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Schedule'),
          content: const Text(
              'Are you sure you want to delete this schedule? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      await ScheduleService.deleteSchedule(token, scheduleId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule deleted successfully')),
      );

      _loadSchedules(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete schedule: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredSchedules() {
    if (_selectedDate == null) return _schedules;

    final dayFormatter = DateFormat('yyyy-MM-dd');
    final selectedDayStr = dayFormatter.format(_selectedDate!);

    return _schedules.where((schedule) {
      // Filter by date
      final scheduleStart = DateTime.parse(schedule['startTime']);
      final scheduleDay = dayFormatter.format(scheduleStart);
      final isMatchingDay = scheduleDay == selectedDayStr;

      // Filter by status
      final isStatusMatching =
          _statusFilter == 'all' || schedule['status'] == _statusFilter;

      return isMatchingDay && isStatusMatching;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCreateScheduleDialog() {
    _routeController.clear();
    _notesController.clear();
    _startTime = null;
    _endTime = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  hintText: 'Select route',
                  prefixIcon: Icon(Icons.route),
                ),
                readOnly: true,
                onTap: _showRouteSelectionDialog,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      final now = DateTime.now();
                      _startTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                    });
                    Navigator.of(context).pop();
                    _showCreateScheduleDialog();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _startTime == null
                        ? 'Select start time'
                        : DateFormat('HH:mm').format(_startTime!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      final now = DateTime.now();
                      _endTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                    });
                    Navigator.of(context).pop();
                    _showCreateScheduleDialog();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _endTime == null
                        ? 'Select end time'
                        : DateFormat('HH:mm').format(_endTime!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes about this schedule',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: _startTime != null &&
                    _endTime != null &&
                    _routeController.text.isNotEmpty
                ? _createNewSchedule
                : null,
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _startRoute(Map<String, dynamic> schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartRouteScreen(
          vehicleId: schedule['vehicleId'],
          routeId: schedule['routeId'],
          scheduleName: schedule['routeName'],
          scheduleId: schedule['id'],
        ),
      ),
    );
  }

  void _showScheduleDetails(Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final DateTime startTime = DateTime.parse(schedule['startTime']);
        final DateTime endTime = DateTime.parse(schedule['endTime']);
        final status = schedule['status'];

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade50,
                    child: const Icon(Icons.route, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['routeName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Bus ${schedule['vehicleName']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeDisplay(
                      label: 'START',
                      time: startTime,
                      icon: Icons.play_circle_outline,
                    ),
                  ),
                  Expanded(
                    child: _buildTimeDisplay(
                      label: 'END',
                      time: endTime,
                      icon: Icons.stop_circle_outlined,
                    ),
                  ),
                ],
              ),
              if (schedule['notes'] != null &&
                  schedule['notes'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'NOTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(schedule['notes']),
              ],
              const SizedBox(height: 16),
              const Text(
                'STOPS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: schedule['stops'].length,
                  itemBuilder: (context, index) {
                    final stop = schedule['stops'][index];
                    final isCurrentStop =
                        schedule['currentStop'] == stop['name'];
                    final isNextStop = schedule['nextStop'] == stop['name'];

                    return Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isCurrentStop
                                ? Colors.green
                                : isNextStop
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stop['name'],
                            style: TextStyle(
                              fontWeight: isCurrentStop || isNextStop
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(stop['time']),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: status == 'scheduled'
                      ? () => _startRoute(schedule)
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START ROUTE'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in-progress':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTimeDisplay({
    required String label,
    required DateTime time,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(time),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(time),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final DateTime startTime = DateTime.parse(schedule['startTime']);
    final DateTime endTime = DateTime.parse(schedule['endTime']);
    final status = schedule['status'];
    final isInProgress = status == 'in-progress';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInProgress
            ? BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showScheduleDetails(schedule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    child: Icon(
                      isInProgress ? Icons.directions_bus : Icons.schedule,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['routeName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (isInProgress && schedule['progress'] != null) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: schedule['progress'],
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current: ${schedule['currentStop']} → Next: ${schedule['nextStop']}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (status == 'scheduled') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _startRoute(schedule),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('START ROUTE'),
                      style: TextButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status ==
                      'scheduled') // Only allow deleting scheduled routes
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteSchedule(schedule['id']),
                      tooltip: 'Delete schedule',
                    ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showScheduleDetails(schedule),
                    tooltip: 'View details',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabName) {
    final filteredSchedules = _getFilteredSchedules().where((schedule) {
      if (tabName == 'Today') {
        final now = DateTime.now();
        final start = DateTime.parse(schedule['startTime']);
        final end = DateTime.parse(schedule['endTime']);
        return start.day == now.day &&
            start.month == now.month &&
            start.year == now.year;
      } else if (tabName == 'Upcoming') {
        final now = DateTime.now();
        final start = DateTime.parse(schedule['startTime']);
        return start.isAfter(now) && schedule['status'] == 'scheduled';
      } else if (tabName == 'Completed') {
        return schedule['status'] == 'completed';
      }
      return false;
    }).toList();

    if (filteredSchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No $tabName Schedules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tabName == 'Today'
                  ? 'You have no routes scheduled for today'
                  : tabName == 'Upcoming'
                      ? 'No upcoming routes scheduled'
                      : 'No completed routes to show',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        return _buildScheduleCard(filteredSchedules[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Schedules'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Statuses'),
              ),
              const PopupMenuItem(
                value: 'scheduled',
                child: Text('Scheduled'),
              ),
              const PopupMenuItem(
                value: 'in-progress',
                child: Text('In Progress'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: LoadingIndicator(message: 'Loading schedules...'))
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
              : SafeArea(
                  child: Column(
                    children: [
                      // Date indicator
                      if (_selectedDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(_selectedDate!),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              if (_statusFilter != 'all')
                                Chip(
                                  label: Text(_statusFilter.toUpperCase()),
                                  backgroundColor:
                                      _getStatusColor(_statusFilter)
                                          .withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _getStatusColor(_statusFilter),
                                    fontSize: 10,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _statusFilter = 'all';
                                    });
                                  },
                                  deleteIconColor:
                                      _getStatusColor(_statusFilter),
                                ),
                            ],
                          ),
                        ),
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTabContent('Today'),
                            _buildTabContent('Upcoming'),
                            _buildTabContent('Completed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateScheduleDialog,
        tooltip: 'Create Schedule',
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.directions_bus,
                        size: 40, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Driver Schedules',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Manage your route schedules',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                    context, DriverRoutes.driverHome);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedules'),
              selected: true,
              selectedTileColor: Colors.deepPurple.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Map View'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DriverMapScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, DriverRoutes.driverProfile);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
