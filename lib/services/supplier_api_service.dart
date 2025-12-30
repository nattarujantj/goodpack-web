import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier.dart';
import '../config/app_config.dart';

class SupplierApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/suppliers';

  // Get all suppliers
  static Future<List<Supplier>> getSuppliers() async {
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
        
        return decoded.map((json) => Supplier.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load suppliers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading suppliers: $e');
    }
  }

  // Get supplier by ID
  static Future<Supplier> getSupplier(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Supplier.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Supplier not found');
      } else {
        throw Exception('Failed to load supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading supplier: $e');
    }
  }

  // Add new supplier
  static Future<Supplier> addSupplier(SupplierRequest supplierRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplierRequest.toJson()),
      );

      if (response.statusCode == 201) {
        return Supplier.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding supplier: $e');
    }
  }

  // Update supplier
  static Future<Supplier> updateSupplier(String id, SupplierRequest supplierRequest) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplierRequest.toJson()),
      );

      if (response.statusCode == 200) {
        return Supplier.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Supplier not found');
      } else {
        throw Exception('Failed to update supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating supplier: $e');
    }
  }

  // Delete supplier
  static Future<bool> deleteSupplier(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting supplier: $e');
    }
  }
}

