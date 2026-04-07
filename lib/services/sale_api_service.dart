import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sale.dart';
import '../config/app_config.dart';
import 'auth_token.dart';

class SaleApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/sales';

  Future<List<Sale>> getSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: AuthToken.headers,
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
      
      return decoded.map((json) => Sale.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sales: ${response.statusCode}');
    }
  }

  Future<Sale> getSale(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
    );

    if (response.statusCode == 200) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load sale: ${response.statusCode}');
    }
  }

  Future<Sale> addSale(SaleRequest saleRequest) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: AuthToken.headers,
      body: json.encode(saleRequest.toJson()),
    );

    if (response.statusCode == 201) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add sale: ${response.statusCode}');
    }
  }

  Future<Sale> updateSale(String id, SaleRequest saleRequest) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
      body: json.encode(saleRequest.toJson()),
    );

    if (response.statusCode == 200) {
      return Sale.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update sale: ${response.statusCode}');
    }
  }

  Future<void> deleteSale(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete sale: ${response.statusCode}');
    }
  }

  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/$customerId/sales'),
      headers: AuthToken.headers,
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return [];
      final decoded = json.decode(response.body);
      if (decoded == null || decoded is! List) return [];
      return decoded.map((j) => Sale.fromJson(j)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load customer sales: ${response.statusCode}');
    }
  }
}
