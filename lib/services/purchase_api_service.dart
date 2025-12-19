import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/purchase.dart';
import '../config/app_config.dart';

class PurchaseApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/purchases';

  // Get all purchases
  static Future<List<Purchase>> getPurchases() async {
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
        
        return decoded.map((json) => Purchase.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load purchases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading purchases: $e');
    }
  }

  // Get purchase by ID
  static Future<Purchase> getPurchase(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Purchase.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Purchase not found');
      } else {
        throw Exception('Failed to load purchase: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading purchase: $e');
    }
  }

  // Add new purchase
  static Future<Purchase> addPurchase(PurchaseRequest purchaseRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(purchaseRequest.toJson()),
      );

      if (response.statusCode == 201) {
        return Purchase.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add purchase: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding purchase: $e');
    }
  }

  // Update purchase
  static Future<Purchase> updatePurchase(String id, PurchaseRequest purchaseRequest) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(purchaseRequest.toJson()),
      );

      if (response.statusCode == 200) {
        return Purchase.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Purchase not found');
      } else {
        throw Exception('Failed to update purchase: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating purchase: $e');
    }
  }

  // Delete purchase
  static Future<bool> deletePurchase(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting purchase: $e');
    }
  }
}
