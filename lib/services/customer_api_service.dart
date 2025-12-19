import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../config/app_config.dart';

class CustomerApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/customers';

  // Get all customers
  static Future<List<Customer>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      // 200 = success, 404 = no data (treat as empty list)
      if (response.statusCode == 200 || response.statusCode == 404) {
        if (response.statusCode == 404) {
          return [];
        }
        
        if (response.body.isEmpty || response.body == 'null') {
          return [];
        }
        
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! List) {
          return [];
        }
        
        return decoded.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading customers: $e');
    }
  }

  // Get customer by ID
  static Future<Customer> getCustomer(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found');
      } else {
        throw Exception('Failed to load customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading customer: $e');
    }
  }

  // Add new customer
  static Future<Customer> addCustomer(CustomerRequest customerRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerRequest.toJson()),
      );

      if (response.statusCode == 201) {
        return Customer.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding customer: $e');
    }
  }

  // Update customer
  static Future<Customer> updateCustomer(String id, CustomerRequest customerRequest) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerRequest.toJson()),
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found');
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating customer: $e');
    }
  }

  // Delete customer
  static Future<bool> deleteCustomer(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting customer: $e');
    }
  }
}
