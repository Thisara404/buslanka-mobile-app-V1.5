import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/config/config.dart';

class ApiClient {
  static const String baseUrl = ApiConfig.baseUrl;

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParams,
      bool requiresAuth = false}) async {
    try {
      // Build URL with query parameters
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        uri = Uri.parse('$baseUrl$endpoint?$queryString');
      }

      // Prepare headers
      Map<String, String> requestHeaders = headers ?? {};
      
      // Add auth token if required
      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        } else {
          throw Exception('Authentication required but token not found');
        }
      }

      // Make request
      final response = await http.get(uri, headers: requestHeaders);
      return _processResponse(response);
    } catch (e) {
      throw Exception('GET request failed: ${e.toString()}');
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint,
      {required Map<String, dynamic> body,
      Map<String, String>? headers,
      bool requiresAuth = false}) async {
    try {
      // Prepare headers
      Map<String, String> requestHeaders = headers ?? {};
      requestHeaders['Content-Type'] = 'application/json';
      
      // Add auth token if required
      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        } else {
          throw Exception('Authentication required but token not found');
        }
      }

      // Make request
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: requestHeaders,
        body: json.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('POST request failed: ${e.toString()}');
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(String endpoint,
      {required Map<String, dynamic> body,
      Map<String, String>? headers,
      bool requiresAuth = false}) async {
    try {
      // Prepare headers
      Map<String, String> requestHeaders = headers ?? {};
      requestHeaders['Content-Type'] = 'application/json';
      
      // Add auth token if required
      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        } else {
          throw Exception('Authentication required but token not found');
        }
      }

      // Make request
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: requestHeaders,
        body: json.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: ${e.toString()}');
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint,
      {Map<String, String>? headers, bool requiresAuth = false}) async {
    try {
      // Prepare headers
      Map<String, String> requestHeaders = headers ?? {};
      
      // Add auth token if required
      if (requiresAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        } else {
          throw Exception('Authentication required but token not found');
        }
      }

      // Make request
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: requestHeaders,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: ${e.toString()}');
    }
  }

  // Process HTTP response
  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final errorMessage = errorBody != null && errorBody['message'] != null
          ? errorBody['message']
          : 'Request failed with status: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }
}
