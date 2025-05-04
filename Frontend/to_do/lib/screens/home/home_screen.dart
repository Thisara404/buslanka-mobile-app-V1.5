import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/screens/driver/driver_home_screen.dart';
import 'package:to_do/screens/passenger/passenger_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get user role from auth provider
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole;

    // Direct users to the correct home screen based on their role
    if (userRole == 'driver') {
      return const DriverHomeScreen();
    } else {
      // Default to passenger home screen
      return const PassengerHomeScreen();
    }
  }
}
