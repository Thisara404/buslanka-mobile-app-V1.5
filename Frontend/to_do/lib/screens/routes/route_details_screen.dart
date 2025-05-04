import 'package:flutter/material.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/services/schedule_service.dart';
import 'package:to_do/services/vehicle_service.dart';
import 'package:to_do/screens/maps/route_detail_map_screen.dart';
import 'package:intl/intl.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteDetailsScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
  }) : super(key: key);

  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _routeData;
  List<dynamic> _schedules = [];
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRouteData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load route details
      _routeData = await RouteService.getRouteById(widget.routeId);

      // Check if route is favorite
      try {
        final favorites = await RouteService.getFavoriteRoutes();
        _isFavorite = favorites.any((route) => route['_id'] == widget.routeId);
      } catch (e) {
        // User might not be logged in, ignore
      }

      // Load schedules
      _schedules = await ScheduleService.getSchedulesByRoute(widget.routeId);

      // Load vehicles
      // _vehicles = await VehicleService.getVehiclesByRoute(widget.routeId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route details: $e';
      });
      print('Error loading route data: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      bool success;

      if (_isFavorite) {
        success = await RouteService.removeFromFavorites(widget.routeId);
      } else {
        success = await RouteService.addToFavorites(widget.routeId);
      }

      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Route added to favorites'
                : 'Route removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailMapScreen(
          routeId: widget.routeId,
          routeName: widget.routeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _viewOnMap,
            tooltip: 'View on map',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Schedule'),
            Tab(text: 'Buses'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildScheduleTab(),
                    _buildBusesTab(),
                  ],
                ),
    );
  }

  Widget _buildDetailsTab() {
    if (_routeData == null) {
      return const Center(child: Text('No route information available'));
    }

    final stops = _routeData!['stops'] ?? [];
    final distance = _routeData!['distance'] ?? 0;
    final duration = _routeData!['estimatedDuration'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Text(
                    'Description: ${_routeData!['description'] ?? 'No description'}'),
                const SizedBox(height: 8),
                Text('Distance: ${(distance / 1000).toStringAsFixed(2)} km'),
                const SizedBox(height: 8),
                Text('Duration: ${(duration / 60).round()} minutes'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _viewOnMap,
                  icon: const Icon(Icons.map),
                  label: const Text('VIEW LIVE TRACKING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Stops (${stops.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...List.generate(
          stops.length,
          (index) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(stops[index]['name'] ?? 'Unnamed stop'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('No schedules available'));
    }

    final dateFormat = DateFormat('HH:mm');

    return ListView.builder(
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final startTime = DateTime.parse(schedule['startTime']);
        final endTime = DateTime.parse(schedule['endTime']);
        final days = schedule['dayOfWeek'] ?? [];
        final status = schedule['status'] ?? 'unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status == 'in-progress'
                          ? Icons.directions_bus
                          : status == 'scheduled'
                              ? Icons.schedule
                              : Icons.cancel,
                      color: status == 'in-progress'
                          ? Colors.green
                          : status == 'scheduled'
                              ? Colors.blue
                              : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(startTime)} - ${dateFormat.format(endTime)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(status.toUpperCase()),
                      backgroundColor: status == 'in-progress'
                          ? Colors.green[100]
                          : status == 'scheduled'
                              ? Colors.blue[100]
                              : Colors.red[100],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Days: ${days.join(", ")}'),
                const SizedBox(height: 8),
                if (schedule['vehicleId'] != null)
                  Text(
                      'Bus: ${schedule['vehicleId']['busNumber'] ?? 'Unassigned'}'),
                if (schedule['driverId'] != null)
                  Text(
                      'Driver: ${schedule['driverId']['name'] ?? 'Unassigned'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusesTab() {
    if (_vehicles.isEmpty) {
      return const Center(child: Text('No buses assigned to this route'));
    }

    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final status = vehicle['status'] ?? 'unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Icon(
              Icons.directions_bus,
              color: status == 'active'
                  ? Colors.green
                  : status == 'maintenance'
                      ? Colors.orange
                      : Colors.grey,
              size: 36,
            ),
            title: Text(vehicle['busNumber'] ?? 'Unknown bus'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicle['busModel'] != null)
                  Text('Model: ${vehicle['busModel']}'),
                if (vehicle['busColor'] != null)
                  Text('Color: ${vehicle['busColor']}'),
              ],
            ),
            trailing: Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: status == 'active'
                  ? Colors.green[100]
                  : status == 'maintenance'
                      ? Colors.orange[100]
                      : Colors.grey[300],
            ),
          ),
        );
      },
    );
  }
}
