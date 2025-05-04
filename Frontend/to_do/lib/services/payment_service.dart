import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:to_do/config/api_config.dart';
import 'package:to_do/config/config.dart';
import 'package:to_do/models/local_storage.dart';

class PaymentService {
  final LocalStorage _localStorage = LocalStorage();
  
  Future<Map<String, dynamic>> createPaymentOrder(String journeyId, double amount) async {
    try {
      final token = await _localStorage.getToken();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'journeyId': journeyId,
          'amount': amount,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create payment order');
      }
    } catch (e) {
      throw Exception('Error creating payment order: $e');
    }
  }
  
  Future<Map<String, dynamic>> capturePayment(String orderId) async {
    try {
      final token = await _localStorage.getToken();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/capture/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to capture payment');
      }
    } catch (e) {
      throw Exception('Error capturing payment: $e');
    }
  }
  
  Future<List<dynamic>> getPaymentHistory({int page = 1, int limit = 10}) async {
    try {
      final token = await _localStorage.getToken();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/history?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data']['payments'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment history');
      }
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }
  
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final token = await _localStorage.getToken();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment details');
      }
    } catch (e) {
      throw Exception('Error getting payment details: $e');
    }
  }
}