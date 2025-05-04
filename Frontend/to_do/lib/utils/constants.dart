class AppConstants {
  // App information
  static const String appName = 'Bus Tracking App';
  static const String appVersion = '1.0.0';

  // Route related constants
  static const int defaultAnimationDurationMs = 300;
  static const double defaultMapZoom = 15.0;
  static const double closeMapZoom = 18.0;
  static const double farMapZoom = 12.0;

  // Preferences keys
  static const String prefFirstLaunch = 'first_launch';
  static const String prefSelectedLanguage = 'selected_language';
  static const String prefNotificationsEnabled = 'notificationsEnabled';
  static const String prefLocationTrackingEnabled = 'locationTrackingEnabled';
  static const String prefDarkModeEnabled = 'darkModeEnabled';
  static const String prefSelectedTheme = 'selectedTheme';
  static const String prefSelectedDistance = 'selectedDistance';

  // Distance units
  static const String unitKilometers = 'Kilometers';
  static const String unitMiles = 'Miles';

  // Theme modes
  static const String themeSystem = 'System Default';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';

  // User roles
  static const String rolePassenger = 'passenger';
  static const String roleDriver = 'driver';

  // Vehicle statuses
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusMaintenance = 'maintenance';
}

class ApiEndpoints {
  // Base URL is already in ApiConfig class in config.dart

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // User endpoints
  static const String profile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile/update';
  static const String changePassword = '/api/users/password';

  // Routes and scheduling
  static const String routes = '/api/routes';
  static const String nearbyRoutes = '/api/routes/nearby';
  static const String searchRoutes = '/api/routes/search';
  static const String schedules = '/api/schedules';
  static const String vehicles = '/api/vehicles';
}

class ErrorMessages {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String authFailed =
      'Authentication failed. Please check your credentials.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';
  static const String locationPermissionDenied =
      'Location permission is required for this feature.';
  static const String locationDisabled =
      'Please enable location services to use this feature.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
}
