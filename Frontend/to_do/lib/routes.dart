import 'package:flutter/material.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/screens/auth/register_screen.dart';
import 'package:to_do/screens/driver/create_route_screen.dart';
import 'package:to_do/screens/driver/driver_home_screen.dart';
import 'package:to_do/screens/driver/driver_profile_screen.dart';
import 'package:to_do/screens/driver/start_route_screen.dart';
import 'package:to_do/screens/home/home_screen.dart';
import 'package:to_do/screens/maps/nearby_buses_screen.dart';
import 'package:to_do/screens/maps/route_map_screen.dart';
import 'package:to_do/screens/onboarding/language_selection_screen.dart';
import 'package:to_do/screens/onboarding/role_selection_screen.dart';
import 'package:to_do/screens/passenger/favorites_screen.dart';
import 'package:to_do/screens/passenger/passenger_home_screen.dart';
import 'package:to_do/screens/passenger/passenger_profile_screen.dart';
import 'package:to_do/screens/passenger/route_search_screen.dart';
import 'package:to_do/screens/routes/routes_list_screen.dart';
import 'package:to_do/screens/routes/route_details_screen.dart';
import 'package:to_do/screens/settings/settings_screen.dart';

// Define route names as constants
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding routes
  static const String languageSelection = '/language-selection';
  static const String roleSelection = '/role-selection';

  // Main routes
  static const String home = '/home';
  static const String passengerHome = '/passenger-home';
  static const String driverHome = '/driver-home';

  // Profile routes
  static const String passengerProfile = '/passenger-profile';
  static const String driverProfile = '/driver-profile';

  // Route related
  static const String routesList = '/routes-list';
  static const String routeDetails = '/route-details';
  static const String routeMap = '/route-map';
  static const String routeSearch = '/route-search';
  static const String nearbyBuses = '/nearby-buses';
  static const String favorites = '/favorites';
  static const String createRoute = '/create-route';

  // Driver specific
  static const String startRoute = '/start-route';

  // Settings
  static const String settings = '/settings';
}

// Create the route generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(
            isPassenger: args?['isPassenger'] ?? true,
          ),
        );

      case AppRoutes.languageSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LanguageSelectionScreen(
            isOnboarding: args?['isOnboarding'] ?? true,
          ),
        );

      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.passengerHome:
        return MaterialPageRoute(builder: (_) => const PassengerHomeScreen());

      case AppRoutes.driverHome:
        return MaterialPageRoute(builder: (_) => const DriverHomeScreen());

      case AppRoutes.passengerProfile:
        return MaterialPageRoute(
            builder: (_) => const PassengerProfileScreen());

      case AppRoutes.driverProfile:
        return MaterialPageRoute(builder: (_) => const DriverProfileScreen());

      case AppRoutes.routesList:
        return MaterialPageRoute(builder: (_) => const RoutesListScreen());

      case AppRoutes.routeDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RouteDetailsScreen(
            routeId: args['routeId'],
            routeName: args['routeName'],
          ),
        );

      case AppRoutes.routeMap:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RouteMapScreen(
            routeId: args['routeId'],
            routeName: args['routeName'],
          ),
        );

      case AppRoutes.routeSearch:
        return MaterialPageRoute(builder: (_) => const RouteSearchScreen());

      case AppRoutes.nearbyBuses:
        return MaterialPageRoute(builder: (_) => const NearbyBusesScreen());

      case AppRoutes.favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());

      case AppRoutes.startRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StartRouteScreen(
            vehicleId: args['vehicleId'],
            routeId: args['routeId'],
            scheduleName: args['scheduleName'],
            scheduleId: args['scheduleId'],
          ),
        );

      case AppRoutes.createRoute:
        return MaterialPageRoute(builder: (_) => const CreateRouteScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        // Default to home or return error page
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }

  // Helper method to navigate to a route with parameters
  static void navigateTo(BuildContext context, String routeName,
      {Map<String, dynamic>? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  // Helper method to navigate and replace current route
  static void navigateAndReplace(BuildContext context, String routeName,
      {Map<String, dynamic>? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  // Helper method to navigate and clear all previous routes
  static void navigateAndClearStack(BuildContext context, String routeName,
      {Map<String, dynamic>? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false,
        arguments: arguments);
  }
}
