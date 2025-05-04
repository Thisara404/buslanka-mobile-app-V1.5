import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/providers/location_provider.dart';
import 'package:to_do/providers/vehicle_provider.dart';
import 'package:to_do/screens/maps/nearby_buses_screen.dart';
import 'package:to_do/screens/passenger/favorites_screen.dart';
import 'package:to_do/screens/passenger/passenger_profile_screen.dart';
import 'package:to_do/screens/routes/routes_list_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/widgets/sidebar/passenger/passenger_sidebar.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);

  @override
  _PassengerHomeScreenState createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const RoutesListScreen(),
    const NearbyBusesScreen(),
    const PassengerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // // Initialize vehicle tracking
    // Future.delayed(Duration.zero, () {
    //   final vehicleProvider =
    //       Provider.of<VehicleProvider>(context, listen: false);
    //   vehicleProvider.initialize();
    // });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    return Scaffold(
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
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      drawer: PassengerSidebar(
        selectedIndex: _selectedIndex,
        onIndexSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      // Add logout icon to the app bar
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: _navigateToFavorites,
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}
