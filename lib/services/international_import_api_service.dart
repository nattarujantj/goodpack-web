import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/international_import.dart';
import '../config/app_config.dart';

class InternationalImportApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/international-imports';

  static Future<List<InternationalImport>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! List) return [];
        return decoded.map((j) => InternationalImport.fromJson(j)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load international imports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading international imports: $e');
    }
  }

  static Future<InternationalImport> getById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return InternationalImport.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('International import not found');
      } else {
        throw Exception('Failed to load international import: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading international import: $e');
    }
  }

  static Future<InternationalImport> create(InternationalImportRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 201) {
        return InternationalImport.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create international import: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating international import: $e');
    }
  }

  static Future<InternationalImport> update(String id, InternationalImportRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 200) {
        return InternationalImport.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('International import not found');
      } else {
        throw Exception('Failed to update international import: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating international import: $e');
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
      throw Exception('Error deleting international import: $e');
    }
  }

  static Future<Map<String, dynamic>> createPurchaseFromImport(String id, {required bool isVAT}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/$id/create-purchase'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isVAT': isVAT}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final body = response.body;
        throw Exception('Failed to create purchase: $body');
      }
    } catch (e) {
      throw Exception('Error creating purchase from import: $e');
    }
  }
}
