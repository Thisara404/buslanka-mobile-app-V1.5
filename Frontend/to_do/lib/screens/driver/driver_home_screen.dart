import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/screens/driver/route_management_screen.dart';
import 'package:to_do/screens/driver/start_route_screen.dart';
import 'package:to_do/screens/driver/driver_profile_screen.dart';
import 'package:to_do/screens/driver/driver_schedules_screen.dart';
import 'package:to_do/screens/driver/driver_map_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:to_do/services/vehicle_service.dart';
import 'package:to_do/services/schedule_service.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';
import 'package:to_do/widgets/driver/status_toggle.dart';
import 'package:to_do/routes.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum DriverStatus { active, inactive, maintenance }

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _vehicleData;
  Map<String, dynamic>? _currentSchedule;
  bool _isChangingStatus = false;
  DriverStatus _currentStatus = DriverStatus.inactive;
  String? _errorMessage;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // List of screens to navigate to
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadDriverData();

    // Initialize screens list
    _screens = [
      _buildDashboardContent(),
      const DriverMapScreen(),
      const DriverProfileScreen(),
    ];
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load driver profile
      final driverId = Provider.of<AuthProvider>(context, listen: false).userId;

      // TODO: Replace with actual API calls when implemented
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 800));

      _driverData = {
        'id': driverId,
        'name': 'John Driver',
        'email': 'john.driver@example.com',
        'phone': '+1 555-1234',
        'address': '123 Main Street, City',
        'image':
            'https://ui-avatars.com/api/?name=John+Driver&background=random',
      };

      _vehicleData = {
        'id': 'vehicle-123',
        'busNumber': 'BUS-1234',
        'busModel': 'City Express',
        'busColor': 'Blue',
        'status': 'inactive',
        'route': {'id': 'route-123', 'name': 'City Center - Airport'}
      };

      _currentSchedule = {
        'id': 'schedule-123',
        'startTime':
            DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        'endTime':
            DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
        'status': 'scheduled',
      };

      // Set up the location provider with driver and vehicle info
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      locationProvider.setDriverAndVehicle(driverId, _vehicleData!['id']);

      // Get current status
      _currentStatus = _parseVehicleStatus(_vehicleData!['status']);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load driver data: $e';
      });
      print('Error loading driver data: $e');
    }
  }

  DriverStatus _parseVehicleStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return DriverStatus.active;
      case 'maintenance':
        return DriverStatus.maintenance;
      case 'inactive':
      default:
        return DriverStatus.inactive;
    }
  }

  Future<void> _onStatusChanged(DriverStatus newStatus) async {
    if (_isChangingStatus) return;

    setState(() {
      _isChangingStatus = true;
    });

    try {
      // Change status logic
      await Future.delayed(const Duration(seconds: 1)); // Mock API call

      // Update status in UI
      setState(() {
        _currentStatus = newStatus;
        _isChangingStatus = false;
        _vehicleData!['status'] = _getStatusString(newStatus);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() {
        _isChangingStatus = false;
      });
    }
  }

  String _getStatusString(DriverStatus status) {
    switch (status) {
      case DriverStatus.active:
        return 'active';
      case DriverStatus.maintenance:
        return 'maintenance';
      case DriverStatus.inactive:
        return 'inactive';
    }
  }

  void _startRoute() {
    if (_vehicleData != null && _currentSchedule != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StartRouteScreen(
            vehicleId: _vehicleData!['id'],
            routeId: _vehicleData!['route']['id'],
            scheduleName: _vehicleData!['route']['name'],
            scheduleId: _currentSchedule!['id'],
          ),
        ),
      );
    }
  }

  void _navigateToSchedules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverSchedulesScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToRouteManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteManagementScreen()),
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: LoadingIndicator(message: 'Loading driver data...')),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDriverData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // User profile header with status
          Container(
            color: Colors.deepPurple,
            padding: const EdgeInsets.only(top: 50, bottom: 16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image with status indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _driverData?['image'] != null
                          ? NetworkImage(_driverData!['image'])
                          : null,
                      backgroundColor: Colors.white,
                      child: _driverData?['image'] == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.deepPurple)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: _getStatusColor(),
                          radius: 10,
                          child: Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Driver name
                Text(
                  _driverData?['name'] ?? 'Driver',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Status text
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_getStatusString(_currentStatus).toUpperCase()} MODE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.route),
                  title: const Text('Routes'),
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSchedules();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Timetable'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Timetable feature coming soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Maps'),
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: const Text('Manage Routes'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _navigateToRouteManagement();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case DriverStatus.active:
        return Colors.green;
      case DriverStatus.maintenance:
        return Colors.orange;
      case DriverStatus.inactive:
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case DriverStatus.active:
        return Icons.check_circle;
      case DriverStatus.maintenance:
        return Icons.build;
      case DriverStatus.inactive:
      default:
        return Icons.do_not_disturb;
    }
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDriverData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and status indicator
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Driver Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusString(_currentStatus).toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status toggle buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isChangingStatus
                                ? null
                                : () => _onStatusChanged(DriverStatus.active),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('ACTIVE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentStatus == DriverStatus.active
                                      ? Colors.green
                                      : Colors.grey.shade300,
                              foregroundColor:
                                  _currentStatus == DriverStatus.active
                                      ? Colors.white
                                      : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isChangingStatus
                                ? null
                                : () => _onStatusChanged(DriverStatus.inactive),
                            icon: const Icon(Icons.do_not_disturb),
                            label: const Text('INACTIVE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentStatus == DriverStatus.inactive
                                      ? Colors.grey
                                      : Colors.grey.shade300,
                              foregroundColor:
                                  _currentStatus == DriverStatus.inactive
                                      ? Colors.white
                                      : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isChangingStatus
                                ? null
                                : () =>
                                    _onStatusChanged(DriverStatus.maintenance),
                            icon: const Icon(Icons.build),
                            label: const Text('MAINTENANCE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentStatus == DriverStatus.maintenance
                                      ? Colors.orange
                                      : Colors.grey.shade300,
                              foregroundColor:
                                  _currentStatus == DriverStatus.maintenance
                                      ? Colors.white
                                      : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isChangingStatus)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Updating status...',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Current Assignment Section
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Assignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Vehicle info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      title: Text(
                        _vehicleData != null
                            ? _vehicleData!['busNumber']
                            : 'No vehicle assigned',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: _vehicleData != null
                          ? Text(
                              '${_vehicleData!['busModel']} • ${_vehicleData!['busColor']}')
                          : null,
                    ),

                    // Route info
                    if (_vehicleData != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(
                            Icons.map,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        title: Text(
                          _vehicleData!['route']['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Assigned Route'),
                      ),
                  ],
                ),
              ),
            ),

            // Schedule Section
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Today\'s Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _navigateToSchedules,
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('VIEW ALL'),
                          style: TextButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Schedule content
                  _currentSchedule == null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No schedules for today',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check the schedule tab for upcoming assignments',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Schedule time
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildScheduleTimeDisplay(
                                      label: 'START TIME',
                                      time: DateTime.parse(
                                          _currentSchedule!['startTime']),
                                      icon: Icons.play_circle_outline,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildScheduleTimeDisplay(
                                      label: 'END TIME',
                                      time: DateTime.parse(
                                          _currentSchedule!['endTime']),
                                      icon: Icons.stop_circle_outlined,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Status badge
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getScheduleStatusColor(
                                            _currentSchedule!['status'])
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getScheduleStatusColor(
                                          _currentSchedule!['status']),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _currentSchedule!['status'].toUpperCase(),
                                    style: TextStyle(
                                      color: _getScheduleStatusColor(
                                          _currentSchedule!['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Start route button
                              if (_currentStatus == DriverStatus.active)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _startRoute,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('START ROUTE'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScheduleStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in-progress':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildScheduleTimeDisplay({
    required String label,
    required DateTime time,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(width: 12),
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
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InfoItem {
  final String label;
  final String value;

  InfoItem({required this.label, required this.value});
}
