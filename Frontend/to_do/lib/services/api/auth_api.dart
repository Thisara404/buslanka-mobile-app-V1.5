import 'package:to_do/services/api/api_client.dart';
import 'package:to_do/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  // Passenger login
  static Future<Map<String, dynamic>> loginPassenger(
      String email, String password) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.loginPassengerEndpoint,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response['status'] == true && response['data'] != null) {
        // Fix: Handle possible null values with null-aware operators
        final token = response['token'] ?? response['data']?['token'];
        final userId = response['data']?['_id'] ?? response['data']?['userId'];

        // Only save if both values are not null
        if (token != null && userId != null) {
          await _saveAuthData(
            token,
            userId,
            'passenger',
          );
        }
      }

      return response;
    } catch (e) {
      throw Exception('Passenger login failed: ${e.toString()}');
    }
  }

  // Driver login
  static Future<Map<String, dynamic>> loginDriver(
      String email, String password) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.loginDriverEndpoint,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response['status'] == true && response['data'] != null) {
        // Fix: Handle possible null values with null-aware operators
        final token = response['token'] ?? response['data']?['token'];
        final userId = response['data']?['_id'] ?? response['data']?['userId'];

        // Only save if both values are not null
        if (token != null && userId != null) {
          await _saveAuthData(
            token,
            userId,
            'driver',
          );
        }
      }

      return response;
    } catch (e) {
      throw Exception('Driver login failed: ${e.toString()}');
    }
  }

  // Passenger registration
  static Future<Map<String, dynamic>> registerPassenger(
      Map<String, dynamic> userData) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.registerPassengerEndpoint,
        body: userData,
      );
      return response;
    } catch (e) {
      throw Exception('Passenger registration failed: ${e.toString()}');
    }
  }

  // Driver registration
  static Future<Map<String, dynamic>> registerDriver(
      Map<String, dynamic> userData) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.registerDriverEndpoint,
        body: userData,
      );
      return response;
    } catch (e) {
      throw Exception('Driver registration failed: ${e.toString()}');
    }
  }

  // // Forgot password
  // static Future<Map<String, dynamic>> forgotPassword(String email) async {
  //   try {
  //     final response = await ApiClient.post(
  //       ApiConfig.forgotPasswordEndpoint,
  //       body: {
  //         'email': email,
  //       },
  //     );
  //     return response;
  //   } catch (e) {
  //     throw Exception('Forgot password request failed: ${e.toString()}');
  //   }
  // }

  // // Reset password
  // static Future<Map<String, dynamic>> resetPassword(
  //     String token, String password) async {
  //   try {
  //     final response = await ApiClient.post(
  //       ApiConfig.resetPasswordEndpoint,
  //       body: {
  //         'token': token,
  //         'password': password,
  //       },
  //     );
  //     return response;
  //   } catch (e) {
  //     throw Exception('Password reset failed: ${e.toString()}');
  //   }
  // }

  // Request password reset for passenger
  static Future<Map<String, dynamic>> requestPasswordResetPassenger(
      String email) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordRequestPassengerEndpoint,
        body: {
          'email': email,
        },
      );
      return response;
    } catch (e) {
      throw Exception(
          'Passenger password reset request failed: ${e.toString()}');
    }
  }

  // Request password reset for driver
  static Future<Map<String, dynamic>> requestPasswordResetDriver(
      String email) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordRequestDriverEndpoint,
        body: {
          'email': email,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Driver password reset request failed: ${e.toString()}');
    }
  }

  // Reset password for passenger
  static Future<Map<String, dynamic>> resetPasswordPassenger(
      String email, String resetCode, String newPassword) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordConfirmPassengerEndpoint,
        body: {
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Passenger password reset failed: ${e.toString()}');
    }
  }

  // Reset password for driver
  static Future<Map<String, dynamic>> resetPasswordDriver(
      String email, String resetCode, String newPassword) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordConfirmDriverEndpoint,
        body: {
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Driver password reset failed: ${e.toString()}');
    }
  }

  // Validate token
  static Future<bool> validateToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);
      final userRole = prefs.getString(ApiConfig.userRoleKey);

      if (token == null || userRole == null) {
        return false;
      }

      final endpoint = userRole == 'passenger'
          ? '${ApiConfig.validateTokenEndpoint}/passenger'
          : '${ApiConfig.validateTokenEndpoint}/driver';

      final response = await ApiClient.get(endpoint, requiresAuth: true);
      return response['status'] == true;
    } catch (e) {
      print('Token validation failed: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userIdKey);
    await prefs.remove(ApiConfig.userRoleKey);
  }

  // Save authentication data to secure storage
  static Future<void> _saveAuthData(
      String token, String userId, String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
    await prefs.setString(ApiConfig.userIdKey, userId);
    await prefs.setString(ApiConfig.userRoleKey, userRole);
  }
}
