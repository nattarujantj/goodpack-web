import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/customer.dart';

class CustomerService {
  static String get _baseUrl => '${EnvConfig.apiUrl}/customers';

  // Get customer by ID
  static Future<Customer?> getCustomerById(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$customerId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Customer.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Customer not found
      } else {
        print('Error fetching customer: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching customer: $e');
      return null;
    }
  }

  // Get all customers
  static Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        print('Error fetching customers: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }
}
