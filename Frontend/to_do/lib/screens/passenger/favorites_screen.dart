import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/screens/routes/route_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favoriteRoutes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavoriteRoutes();
  }

  Future<void> _loadFavoriteRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final favoriteRoutes = await RouteService.getFavoriteRoutes();

      setState(() {
        _favoriteRoutes = favoriteRoutes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load favorite routes: $e';
      });
      print('Error loading favorite routes: $e');
    }
  }

  Future<void> _removeFromFavorites(String routeId) async {
    try {
      final success = await RouteService.removeFromFavorites(routeId);

      if (success) {
        // Remove the route from local list
        setState(() {
          _favoriteRoutes.removeWhere((route) => route['_id'] == routeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route removed from favorites'),
            duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Routes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _favoriteRoutes.isEmpty
                  ? const Center(child: Text('No favorite routes'))
                  : RefreshIndicator(
                      onRefresh: _loadFavoriteRoutes,
                      child: ListView.builder(
                        itemCount: _favoriteRoutes.length,
                        itemBuilder: (context, index) {
                          final route = _favoriteRoutes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            child: ListTile(
                              leading: const Icon(Icons.directions_bus),
                              title: Text(route['name'] ?? 'Unnamed route'),
                              subtitle: Text(
                                route['description'] ??
                                    'No description available',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red),
                                onPressed: () =>
                                    _removeFromFavorites(route['_id']),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RouteDetailsScreen(
                                      routeId: route['_id'],
                                      routeName: route['name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
