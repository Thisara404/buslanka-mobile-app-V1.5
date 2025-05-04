import 'package:flutter/material.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/screens/driver/create_route_screen.dart';
import 'package:to_do/screens/maps/route_detail_map_screen.dart';
import 'package:intl/intl.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({Key? key}) : super(key: key);

  @override
  _RouteManagementScreenState createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _routes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final routes = await RouteService.getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load routes: $e';
      });
      print('Error loading routes: $e');
    }
  }

  Future<void> _createNewRoute() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRouteScreen()),
    );

    if (result == true) {
      _loadRoutes(); // Refresh list after creating a new route
    }
  }

  Future<void> _deleteRoute(String routeId) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Route'),
          content: const Text(
              'Are you sure you want to delete this route? This action cannot be undone.'),
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

      await RouteService.deleteRoute(routeId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route deleted successfully')),
      );

      _loadRoutes(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete route: $e')),
      );
    }
  }

  void _viewRouteDetails(dynamic route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailMapScreen(
          routeId: route['_id'],
          routeName: route['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRoutes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _routes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No routes found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createNewRoute,
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Route'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.route),
                            ),
                            title: Text(route['name'] ?? 'Unnamed Route'),
                            subtitle: Text(
                              route['description'] ?? 'No description',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.map),
                                  onPressed: () => _viewRouteDetails(route),
                                  tooltip: 'View on map',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteRoute(route['_id']),
                                  tooltip: 'Delete route',
                                ),
                              ],
                            ),
                            onTap: () => _viewRouteDetails(route),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRoute,
        tooltip: 'Create Route',
        child: const Icon(Icons.add),
      ),
    );
  }
}
