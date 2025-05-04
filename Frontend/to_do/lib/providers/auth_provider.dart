import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/config/config.dart';
import 'package:to_do/services/api/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _token = '';
  String _userId = '';
  String _userRole = '';
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get token => _token;
  String get userId => _userId;
  String get userRole => _userRole;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    final userId = prefs.getString(ApiConfig.userIdKey);
    final userRole = prefs.getString(ApiConfig.userRoleKey);

    if (token != null && userId != null && userRole != null) {
      _token = token;
      _userId = userId;
      _userRole = userRole;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password, bool isPassenger) async {
    try {
      final response = isPassenger
          ? await AuthApi.loginPassenger(email, password)
          : await AuthApi.loginDriver(email, password);

      if (response['status'] == true) {
        // Fix: Safely access token and userId with null-aware operators
        _token = response['token'] ?? response['data']?['token'];
        _userId = response['data']?['_id'] ?? response['data']?['userId'];
        _userRole = isPassenger ? 'passenger' : 'driver';
        _isAuthenticated = _token != null && _userId != null;

        notifyListeners();
        return _isAuthenticated;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<bool> register(
      Map<String, dynamic> registrationData, bool isPassenger) async {
    try {
      final response = isPassenger
          ? await AuthApi.registerPassenger(registrationData)
          : await AuthApi.registerDriver(registrationData);

      return response['status'] == true;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Request a password reset: sends a reset code to the user's email
  Future<bool> requestPasswordReset(String email, bool isPassenger) async {
    try {
      final response = isPassenger
          ? await AuthApi.requestPasswordResetPassenger(email)
          : await AuthApi.requestPasswordResetDriver(email);

      return response['status'] == true;
    } catch (e) {
      throw Exception('Password reset request failed: ${e.toString()}');
    }
  }

  // Reset password with the code received via email
  Future<bool> resetPassword(
    String email,
    String resetCode,
    String newPassword,
    bool isPassenger,
  ) async {
    try {
      final response = isPassenger
          ? await AuthApi.resetPasswordPassenger(email, resetCode, newPassword)
          : await AuthApi.resetPasswordDriver(email, resetCode, newPassword);

      return response['status'] == true;
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  Future<bool> validateToken() async {
    try {
      return await AuthApi.validateToken();
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await AuthApi.logout();

    _token = '';
    _userId = '';
    _userRole = '';
    _isAuthenticated = false;
    notifyListeners();
  }
}
