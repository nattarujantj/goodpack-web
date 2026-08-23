import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fcl_shipment.dart';
import '../models/international_import.dart';
import '../config/app_config.dart';
import 'auth_token.dart';

class FclShipmentApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/fcl-shipments';

  static Future<List<FclShipment>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: AuthToken.headers,
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return [];
        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! List) return [];
        return decoded.map((j) => FclShipment.fromJson(j)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load FCL shipments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading FCL shipments: $e');
    }
  }

  static Future<FclShipment> getById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
    );
    if (response.statusCode == 200) {
      return FclShipment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load FCL shipment: ${response.statusCode}');
  }

  static Future<List<InternationalImport>> getImports(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_endpoint/$id/imports'),
      headers: AuthToken.headers,
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return [];
      final decoded = json.decode(response.body);
      if (decoded == null || decoded is! List) return [];
      return decoded.map((j) => InternationalImport.fromJson(j)).toList();
    }
    throw Exception('Failed to load container imports: ${response.statusCode}');
  }

  static Future<FclShipment> create(FclShipmentRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: AuthToken.headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 201) {
      return FclShipment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create FCL shipment: ${response.body}');
  }

  static Future<FclShipment> update(String id, FclShipmentRequest request) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return FclShipment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update FCL shipment: ${response.body}');
  }

  static Future<bool> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
    );
    if (response.statusCode == 200) return true;
    throw Exception('Failed to delete FCL shipment: ${response.body}');
  }

  static Future<FclShipment> close(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$_endpoint/$id/close'),
      headers: AuthToken.headers,
    );
    if (response.statusCode == 200) {
      return FclShipment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to close container: ${response.body}');
  }

  static Future<FclShipment> reopen(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$_endpoint/$id/reopen'),
      headers: AuthToken.headers,
    );
    if (response.statusCode == 200) {
      return FclShipment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to reopen container: ${response.body}');
  }
}
