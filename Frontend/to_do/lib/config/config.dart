class ApiConfig {
  // Base URL for API calls
  static const String baseUrl = 'http://192.168.43.187:3001';

  // Auth endpoints
  static const String loginPassengerEndpoint = '/api/auth/passenger/login';
  static const String loginDriverEndpoint = '/api/auth/driver/login';
  static const String registerPassengerEndpoint =
      '/api/auth/passenger/register';
  static const String registerDriverEndpoint = '/api/auth/driver/register';
  static const String resetPasswordRequestPassengerEndpoint =
      '/api/auth/passenger/forgot-password';
  static const String resetPasswordRequestDriverEndpoint =
      '/api/auth/driver/forgot-password';
  static const String resetPasswordConfirmPassengerEndpoint =
      '/api/auth/passenger/reset-password';
  static const String resetPasswordConfirmDriverEndpoint =
      '/api/auth/driver/reset-password';
  static const String validateTokenEndpoint =
      '/api/auth/passenger/validate-token';

  // Routes endpoints
  static const String routesEndpoint = '/api/routes';
  static const String nearbyRoutesEndpoint = '/api/routes/nearby';
  static const String searchRoutesEndpoint = '/api/routes/search';
  static const String routeDirectionsEndpoint = '/api/routes';
  static const String geocodeEndpoint = '/api/routes/geocode';

  // Schedules endpoints
  static const String schedulesEndpoint = '/api/schedules';
  static const String scheduleByRouteEndpoint = '/api/schedules/route';
  static const String scheduleArrivalTimesEndpoint = '/api/schedules';

  // // Vehicles endpoints
  // static const String vehiclesEndpoint = '/api/vehicles';
  // static const String vehicleLocationEndpoint = '/api/vehicles';
  // static const String vehicleStatusEndpoint = '/api/vehicles';
  // static const String vehiclesByRouteEndpoint = '/api/vehicles/route';

  // Users endpoints
  static const String usersEndpoint = '/api/users';
  static const String userFavoritesEndpoint = '/api/users/favorites';
  static const String updatePasswordEndpoint = '/api/users/password';
  static const String updateDriverProfileEndpoint = '/api/users/driver/profile';
  static const String updatePassengerProfileEndpoint =
      '/api/users/passenger/profile';

  // Socket.IO connection
  static const String socketUrl = 'http://192.168.43.187:3001';

  // Token storage key
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  // Cache timeouts (in minutes)
  static const int routeCacheTimeout = 60; // 1 hour
  static const int scheduleCacheTimeout = 30; // 30 minutes
  // static const int vehicleCacheTimeout = 5; // 5 minutes
}
