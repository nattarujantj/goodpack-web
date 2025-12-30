import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/supplier.dart';

class SupplierService {
  static String get _baseUrl => '${EnvConfig.apiUrl}/suppliers';

  // Get supplier by ID
  static Future<Supplier?> getSupplierById(String supplierId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$supplierId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Supplier not found
      } else {
        print('Error fetching supplier: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching supplier: $e');
      return null;
    }
  }

  // Get all suppliers
  static Future<List<Supplier>> getAllSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data == null) return [];
        final List<dynamic> jsonList = data;
        return jsonList.map((json) => Supplier.fromJson(json)).toList();
      } else {
        print('Error fetching suppliers: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
      return [];
    }
  }

  // Create supplier
  static Future<Supplier?> createSupplier(SupplierRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data);
      } else {
        print('Error creating supplier: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating supplier: $e');
      return null;
    }
  }

  // Update supplier
  static Future<Supplier?> updateSupplier(String supplierId, SupplierRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$supplierId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data);
      } else {
        print('Error updating supplier: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating supplier: $e');
      return null;
    }
  }

  // Delete supplier
  static Future<bool> deleteSupplier(String supplierId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$supplierId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error deleting supplier: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting supplier: $e');
      return false;
    }
  }
}

