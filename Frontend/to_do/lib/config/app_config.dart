class AppConfig {
  // App information
  static const String appName = 'Bus Tracking App';
  static const String appVersion = '1.0.0';

  // App behavior settings
  static const int sessionTimeoutMinutes = 60;
  static const int locationUpdateIntervalSeconds = 10;
  static const int backgroundServiceIntervalMinutes = 15;
  static const int maxCachedRoutes = 20;
  static const int maxSearchResults = 50;

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = false;
  static const bool enableBackgroundLocationTracking = true;
  static const bool enableAnalytics = false;

  // UI settings
  static const int animationDurationMs = 300;
  static const double defaultPadding = 16.0;
  static const double mapDefaultZoom = 15.0;
  static const double nearbySearchRadiusMeters = 2000;

  // Error messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String defaultErrorMessage =
      'Something went wrong. Please try again.';
  static const String locationPermissionDeniedMessage =
      'Location permission is required for this feature.';
  static const String locationDisabledMessage =
      'Please enable location services to use this feature.';
}
