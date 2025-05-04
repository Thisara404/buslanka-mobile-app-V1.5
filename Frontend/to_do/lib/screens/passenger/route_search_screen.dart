import 'package:flutter/material.dart';
import 'package:to_do/screens/routes/route_details_screen.dart';
import 'package:to_do/services/route_service.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({Key? key}) : super(key: key);

  @override
  _RouteSearchScreenState createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await RouteService.searchRoutes(query);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to search routes: $e';
      });
      print('Error searching routes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Routes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search routes by name, stop, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _searchRoutes();
                } else if (value.isEmpty) {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchRoutes(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _searchResults.isEmpty
                        ? Center(
                            child: _searchController.text.isEmpty
                                ? const Text('Enter a search term')
                                : const Text('No routes found'),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final route = _searchResults[index];
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
                                  trailing: Text(
                                    route['distance'] != null
                                        ? '${(route['distance'] / 1000).toStringAsFixed(1)} km'
                                        : '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RouteDetailsScreen(
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
        ],
      ),
    );
  }
}
