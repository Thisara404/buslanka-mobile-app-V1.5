import 'package:flutter/material.dart';
import 'package:to_do/routes.dart';
import 'package:to_do/services/route_service.dart';
import 'package:to_do/screens/routes/route_details_screen.dart';
import 'package:to_do/utils/map_utils.dart';
import 'package:to_do/widgets/sidebar/passenger/passenger_sidebar.dart';

class RoutesListScreen extends StatefulWidget {
  final bool showAppBar;

  const RoutesListScreen({
    Key? key,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  _RoutesListScreenState createState() => _RoutesListScreenState();
}

class RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;
  final bool isFavorite;
  final Function(bool) onFavoriteToggle;

  const RouteCard({
    Key? key,
    required this.route,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['name'] ?? 'Unnamed Route',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    if (route['description'] != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        route['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (route['stops'] != null &&
                        (route['stops'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${(route['stops'] as List).length} stops',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () => onFavoriteToggle(!isFavorite),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  List<dynamic> _routes = [];
  List<dynamic> _filteredRoutes = [];
  List<dynamic> _favoriteRoutes = [];
  bool _isLoading = true;
  bool _isLoadingFavorites = false;
  bool _showFavoritesOnly = false;
  bool _showNearbyOnly = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadFavoriteRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final routes = await RouteService.getAllRoutes();

      setState(() {
        _routes = routes;
        _filteredRoutes = List.from(routes);
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

  Future<void> _loadFavoriteRoutes() async {
    try {
      setState(() {
        _isLoadingFavorites = true;
      });

      final favorites = await RouteService.getFavoriteRoutes();

      setState(() {
        _favoriteRoutes = favorites;
        _isLoadingFavorites = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFavorites = false;
      });
      // User might not be logged in - ignore error
      print('Error loading favorites: $e');
    }
  }

  Future<void> _loadNearbyRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final location = await MapUtils.getCurrentLocation();

      if (location != null) {
        final nearbyRoutes = await RouteService.getRoutesNearLocation(
          location.latitude!,
          location.longitude!,
        );

        setState(() {
          _filteredRoutes = nearbyRoutes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get current location';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load nearby routes: $e';
      });
      print('Error loading nearby routes: $e');
    }
  }

  void _filterRoutes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRoutes = _showFavoritesOnly
            ? _routes.where((route) => _isFavorite(route['_id'])).toList()
            : List.from(_routes);
      });
      return;
    }

    final filtered = _routes.where((route) {
      final name = route['name'].toString().toLowerCase();
      final description = (route['description'] ?? '').toString().toLowerCase();
      final queryLower = query.toLowerCase();

      final matchesQuery =
          name.contains(queryLower) || description.contains(queryLower);

      if (_showFavoritesOnly) {
        return matchesQuery && _isFavorite(route['_id']);
      }

      return matchesQuery;
    }).toList();

    setState(() {
      _filteredRoutes = filtered;
    });
  }

  bool _isFavorite(String routeId) {
    return _favoriteRoutes.any((route) => route['_id'] == routeId);
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;

      if (_showFavoritesOnly) {
        _showNearbyOnly = false;
        _filteredRoutes =
            _routes.where((route) => _isFavorite(route['_id'])).toList();
      } else {
        _filteredRoutes = List.from(_routes);
      }
    });
  }

  void _toggleNearbyFilter() {
    setState(() {
      _showNearbyOnly = !_showNearbyOnly;

      if (_showNearbyOnly) {
        _showFavoritesOnly = false;
        _loadNearbyRoutes();
      } else {
        _filteredRoutes = List.from(_routes);
      }
    });
  }

  Future<bool> _addFavoriteRoute(String routeId) async {
    try {
      await RouteService.addToFavorites(routeId);

      // Find the route in our list
      final route =
          _routes.firstWhere((r) => r['_id'] == routeId, orElse: () => null);
      if (route != null) {
        setState(() {
          // Add to favorites if not already there
          if (!_favoriteRoutes.any((r) => r['_id'] == routeId)) {
            _favoriteRoutes.add(route);
          }
        });
      }
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  Future<bool> _removeFavoriteRoute(String routeId) async {
    try {
      await RouteService.removeFromFavorites(routeId);

      setState(() {
        _favoriteRoutes.removeWhere((r) => r['_id'] == routeId);

        // If currently showing favorites only, update the filtered list
        if (_showFavoritesOnly) {
          _filteredRoutes =
              _routes.where((route) => _isFavorite(route['_id'])).toList();
        }
      });
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  void _viewRouteDetails(dynamic route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailsScreen(
          routeId: route['_id'],
          routeName: route['name'],
        ),
      ),
    ).then((_) {
      // Refresh favorite routes when coming back
      _loadFavoriteRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Bus Routes'),
            )
          : null,
      drawer:
          widget.showAppBar ? const PassengerSidebar(selectedIndex: 0) : null,
      body: Column(
        children: [
          // Filter buttons above search
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _showFavoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _showFavoritesOnly ? Colors.white : null,
                      size: 20,
                    ),
                    label: Text(_showFavoritesOnly ? 'Favorites' : 'Favorites'),
                    onPressed: _toggleFavoritesFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showFavoritesOnly
                          ? Colors.red
                          : Colors.grey.shade300,
                      foregroundColor:
                          _showFavoritesOnly ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: _showFavoritesOnly ? 2 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _showNearbyOnly
                          ? Icons.location_on
                          : Icons.location_on_outlined,
                      color: _showNearbyOnly ? Colors.white : null,
                      size: 20,
                    ),
                    label: Text(_showNearbyOnly ? 'Nearby' : 'Nearby'),
                    onPressed: _toggleNearbyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _showNearbyOnly ? Colors.blue : Colors.grey.shade300,
                      foregroundColor:
                          _showNearbyOnly ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: _showNearbyOnly ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Routes',
                hintText: 'Enter route name or description',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: _filterRoutes,
            ),
          ),

          // Routes list
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
                              onPressed: _showNearbyOnly
                                  ? _loadNearbyRoutes
                                  : _loadRoutes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredRoutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showFavoritesOnly
                                      ? Icons.favorite_border
                                      : _showNearbyOnly
                                          ? Icons.location_off
                                          : Icons.route_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showFavoritesOnly
                                      ? 'No favorite routes found'
                                      : _showNearbyOnly
                                          ? 'No nearby routes found'
                                          : 'No routes found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _showFavoritesOnly
                                    ? Text(
                                        'Try adding some routes to your favorites',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      )
                                    : _showNearbyOnly
                                        ? Text(
                                            'Try expanding your search area or check your location settings',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.grey.shade600),
                                          )
                                        : Text(
                                            'Try a different search term',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.grey.shade600),
                                          ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_showFavoritesOnly) {
                                      setState(() {
                                        _showFavoritesOnly = false;
                                        _filteredRoutes = List.from(_routes);
                                      });
                                    } else if (_showNearbyOnly) {
                                      setState(() {
                                        _showNearbyOnly = false;
                                        _filteredRoutes = List.from(_routes);
                                      });
                                    } else {
                                      _searchController.clear();
                                      _filterRoutes('');
                                    }
                                  },
                                  child: const Text('Show All Routes'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _showNearbyOnly
                                ? _loadNearbyRoutes
                                : _loadRoutes,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final route = _filteredRoutes[index];
                                return RouteCard(
                                  route: route,
                                  onTap: () => _viewRouteDetails(route),
                                  isFavorite: _isFavorite(route['_id']),
                                  onFavoriteToggle: (isFavorite) async {
                                    bool success = false;

                                    if (isFavorite) {
                                      success =
                                          await _addFavoriteRoute(route['_id']);
                                      if (success) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Added ${route['name']} to favorites')),
                                        );
                                      }
                                    } else {
                                      success = await _removeFavoriteRoute(
                                          route['_id']);
                                      if (success) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Removed ${route['name']} from favorites')),
                                        );
                                      }
                                    }

                                    if (!success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Failed to update favorites')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
