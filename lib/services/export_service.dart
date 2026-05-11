import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import 'auth_token.dart';

class ExportService {
  static String get _baseUrl => EnvConfig.apiUrl;

  /// Export purchases and sales to Excel and send via email
  static Future<Map<String, dynamic>> exportAndSendEmail({
    required int month,
    required int year,
    required List<String> emails,
    bool includeInventory = false,
    int? inventoryMonth,
    int? inventoryYear,
  }) async {
    try {
      final body = <String, dynamic>{
        'month': month,
        'year': year,
        'emails': emails,
        'includeInventory': includeInventory,
      };
      if (includeInventory) {
        body['inventoryMonth'] = inventoryMonth ?? month;
        body['inventoryYear'] = inventoryYear ?? year;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/export/email'),
        headers: AuthToken.headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'message': errorBody['error'] ?? 'เกิดข้อผิดพลาด (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'ไม่สามารถเชื่อมต่อกับ Server: $e',
      };
    }
  }
}

