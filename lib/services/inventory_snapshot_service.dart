import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/inventory_snapshot.dart';
import 'auth_token.dart';

class InventorySnapshotService {
  static String get _baseUrl => EnvConfig.apiUrl;

  static Future<List<InventorySnapshot>> getSnapshots() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inventory-snapshots'),
        headers: AuthToken.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => InventorySnapshot.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<InventorySnapshot?> getSnapshot(int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inventory-snapshots/$year/$month'),
        headers: AuthToken.headers,
      );
      if (response.statusCode == 200) {
        return InventorySnapshot.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> takeManualSnapshot(int month, int year) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/inventory-snapshots'),
        headers: AuthToken.headers,
        body: json.encode({'month': month, 'year': year}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final err = json.decode(response.body);
      return {'success': false, 'message': err['error'] ?? 'เกิดข้อผิดพลาด'};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถเชื่อมต่อ Server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateSnapshot(
    int month,
    int year,
    List<Map<String, dynamic>> products,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/inventory-snapshots/$year/$month'),
        headers: AuthToken.headers,
        body: json.encode({'products': products}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final err = json.decode(response.body);
      return {'success': false, 'message': err['error'] ?? 'เกิดข้อผิดพลาด'};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถเชื่อมต่อ Server: $e'};
    }
  }
}
