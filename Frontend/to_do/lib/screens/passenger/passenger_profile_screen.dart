import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/models/user/passenger.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/screens/passenger/favorites_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:to_do/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({Key? key}) : super(key: key);

  @override
  _PassengerProfileScreenState createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  bool _isLoading = true;
  Passenger? _passengerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPassengerProfile();
  }

  Future<void> _loadPassengerProfile() async {
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
            '${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/passenger/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            _passengerData = Passenger.fromJson(responseData['data']);
            _isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load profile');
        }
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, we'll still show a default profile if API fails
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _passengerData = Passenger(
          id: 'user123',
          name: 'John Doe',
          phone: '555-123-4567',
          email: 'john.doe@example.com',
          addresses: {'home': '123 Main St, City'},
          favoriteRoutes: ['route1', 'route2'],
          image: 'https://ui-avatars.com/api/?name=John+Doe&background=random',
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile not implemented yet')),
    );
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
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
        body: Center(child: CircularProgressIndicator()),
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
                onPressed: _loadPassengerProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPassengerProfile,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                _buildInfoRow('Email', _passengerData!.email),
                _buildInfoRow('Phone', _passengerData!.phone),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Addresses',
              icon: Icons.home,
              children: [
                for (var entry in _passengerData!.addresses.entries)
                  _buildInfoRow('${entry.key.capitalize()}', entry.value),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Account',
              icon: Icons.person,
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favorite Routes'),
                  subtitle: Text(
                      '${_passengerData!.favoriteRoutes.length} routes saved'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _navigateToFavorites,
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Travel History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Travel history not available yet')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _navigateToSettings,
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
              backgroundImage: _passengerData!.image != null
                  ? NetworkImage(_passengerData!.image!)
                  : null,
              child: _passengerData!.image == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _passengerData!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Passenger',
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
