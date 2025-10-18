import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quotation.dart';
import '../config/app_config.dart';

class QuotationApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/quotations';

  Future<List<Quotation>> getQuotations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Quotation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotations: ${response.statusCode}');
    }
  }

  Future<Quotation> getQuotation(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Quotation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load quotation: ${response.statusCode}');
    }
  }

  Future<Quotation> addQuotation(QuotationRequest quotationRequest) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(quotationRequest.toJson()),
    );

    if (response.statusCode == 201) {
      return Quotation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add quotation: ${response.statusCode}');
    }
  }

  Future<Quotation> updateQuotation(String id, QuotationRequest quotationRequest) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(quotationRequest.toJson()),
    );

    if (response.statusCode == 200) {
      return Quotation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update quotation: ${response.statusCode}');
    }
  }

  Future<void> deleteQuotation(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete quotation: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> copyToSale(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint/$id/copy-to-sale'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to copy quotation to sale: ${response.statusCode}');
    }
  }
}
