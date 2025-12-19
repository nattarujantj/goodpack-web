import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ExportService {
  static String get _baseUrl => EnvConfig.apiUrl;

  /// Export purchases and sales to Excel and send via email
  static Future<Map<String, dynamic>> exportAndSendEmail({
    required int month,
    required int year,
    required List<String> emails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/export/email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'month': month,
          'year': year,
          'emails': emails,
        }),
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

