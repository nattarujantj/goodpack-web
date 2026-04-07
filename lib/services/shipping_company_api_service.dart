import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipping_company.dart';
import '../config/app_config.dart';

class ShippingCompanyApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/shipping-companies';

  static Future<List<ShippingCompany>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! List) return [];
        return decoded.map((j) => ShippingCompany.fromJson(j)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load shipping companies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading shipping companies: $e');
    }
  }

  static Future<ShippingCompany> create(ShippingCompanyRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 201) {
        return ShippingCompany.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create shipping company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating shipping company: $e');
    }
  }

  static Future<ShippingCompany> update(String id, ShippingCompanyRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 200) {
        return ShippingCompany.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update shipping company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating shipping company: $e');
    }
  }

  static Future<bool> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting shipping company: $e');
    }
  }
}
