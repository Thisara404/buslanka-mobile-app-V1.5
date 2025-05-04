import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:to_do/widgets/common/loading_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:to_do/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _driverData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/driver/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            _driverData = responseData['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load profile');
        }
      } else {
        // For demo purposes, we'll show mock data if API fails
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          _driverData = {
            'name': 'John Driver',
            'email': 'john.driver@example.com',
            'phone': '+1 555-1234',
            'address': '123 Main Street, City',
            'image':
                'https://ui-avatars.com/api/?name=John+Driver&background=random',
            'busDetails': {
              'busNumber': 'BUS-1234',
              'busModel': 'City Express',
              'busColor': 'Blue',
            },
            'joinDate': '2023-01-15',
            'totalTrips': 342,
            'rating': 4.8,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to mock data in case of error
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _driverData = {
          'name': 'John Driver',
          'email': 'john.driver@example.com',
          'phone': '+1 555-1234',
          'address': '123 Main Street, City',
          'image':
              'https://ui-avatars.com/api/?name=John+Driver&background=random',
          'busDetails': {
            'busNumber': 'BUS-1234',
            'busModel': 'City Express',
            'busColor': 'Blue',
          },
          'joinDate': '2023-01-15',
          'totalTrips': 342,
          'rating': 4.8,
        };
        _isLoading = false;
      });
      print('Error loading profile: $e');
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editProfile() {
    // Navigate to edit profile screen - to be implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile not implemented yet')),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Loading profile...')),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDriverProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Profile header
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // Driver details section
            _buildSection(
              title: 'Driver Details',
              icon: Icons.person,
              children: [
                _buildInfoRow('Email', _driverData['email']),
                _buildInfoRow('Phone', _driverData['phone']),
                _buildInfoRow('Address', _driverData['address']),
                _buildInfoRow(
                    'Joined', _driverData['joinDate'] ?? 'Not available'),
              ],
            ),

            const SizedBox(height: 16),

            // Vehicle details section
            _buildSection(
              title: 'Vehicle Details',
              icon: Icons.directions_bus,
              children: [
                _buildInfoRow(
                  'Bus Number', 
                  _driverData['busDetails']?['busNumber'] ?? 'Not assigned'
                ),
                _buildInfoRow(
                  'Model', 
                  _driverData['busDetails']?['busModel'] ?? 'Not available'
                ),
                _buildInfoRow(
                  'Color', 
                  _driverData['busDetails']?['busColor'] ?? 'Not specified'
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats section
            _buildSection(
              title: 'Stats',
              icon: Icons.bar_chart,
              children: [
                _buildInfoRow(
                    'Total Trips', _driverData['totalTrips'].toString()),
                _buildInfoRow('Rating', '⭐ ${_driverData['rating']}'),
              ],
            ),

            const SizedBox(height: 16),

            // Settings section
            _buildSection(
              title: 'Account',
              icon: Icons.settings,
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _navigateToSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Security settings not available yet')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              backgroundImage: _driverData['image'] != null
                  ? NetworkImage(_driverData['image'])
                  : null,
              child: _driverData['image'] == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _driverData['name'] ?? 'Driver',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bus Driver',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
