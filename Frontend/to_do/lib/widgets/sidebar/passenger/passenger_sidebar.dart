import 'package:flutter/material.dart';
import 'package:to_do/screens/map/map_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';
import 'package:to_do/screens/passenger/passenger_profile_screen.dart';
import 'package:to_do/screens/routes/routes_list_screen.dart';

// Route names for Passenger screens
class PassengerRoutes {
  static const String home = '/passenger_home';
  static const String profile = '/passenger_profile';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String maps = '/maps';
}

class PassengerSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onIndexSelected;

  const PassengerSidebar({
    Key? key,
    this.selectedIndex = 0,
    this.onIndexSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                  'Bus Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Find your route easily',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Routes'),
            selected: selectedIndex == 0,
            selectedTileColor: Colors.deepPurple.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              if (onIndexSelected != null) {
                onIndexSelected!(0);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RoutesListScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map View'),
            selected: selectedIndex == 1,
            selectedTileColor: Colors.deepPurple.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              if (onIndexSelected != null) {
                onIndexSelected!(1);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Timetables'),
            selected: selectedIndex == 2,
            selectedTileColor: Colors.deepPurple.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              // Show a message since the timetables screen doesn't exist yet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Timetables feature coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            selected: selectedIndex == 3,
            selectedTileColor: Colors.deepPurple.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              if (onIndexSelected != null && selectedIndex == 3) {
                onIndexSelected!(3);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PassengerProfileScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorites feature coming soon!')),
              );
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
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            onTap: () {
              Navigator.pop(context);
              // Show a message for now until the Terms screen is created
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Terms & Conditions coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              // Show a message for now until the About screen is created
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('About Us information coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
