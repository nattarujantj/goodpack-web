import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/deposit.dart';
import '../config/app_config.dart';
import 'auth_token.dart';

class DepositApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/deposits';

  static String _errorMessage(http.Response response) {
    final body = response.body.trim();
    return body.isNotEmpty ? body : 'HTTP ${response.statusCode}';
  }

  /// โหลดเงินมัดจำ กรองตามประเภท/คู่ค้าได้
  /// [excludeDocId] ไม่นับยอดที่รายการขาย/ซื้อนี้หักไว้ (ใช้ตอนแก้ไขรายการ)
  /// [availableOnly] เฉพาะมัดจำที่ยังมียอดคงเหลือ
  static Future<List<Deposit>> getDeposits({
    String? type,
    String? partyId,
    String? excludeDocId,
    bool availableOnly = false,
  }) async {
    final params = <String, String>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (partyId != null && partyId.isNotEmpty) 'partyId': partyId,
      if (excludeDocId != null && excludeDocId.isNotEmpty) 'excludeDocId': excludeDocId,
      if (availableOnly) 'available': 'true',
    };
    final uri = Uri.parse('$_baseUrl$_endpoint').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: AuthToken.headers);
    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return [];
      final decoded = json.decode(response.body);
      if (decoded is! List) return [];
      return decoded.map((j) => Deposit.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('โหลดข้อมูลเงินมัดจำไม่สำเร็จ: ${_errorMessage(response)}');
  }

  static Future<Deposit> getDeposit(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl$_endpoint/$id'), headers: AuthToken.headers);
    if (response.statusCode == 200) {
      return Deposit.fromJson(json.decode(response.body));
    }
    throw Exception('โหลดข้อมูลเงินมัดจำไม่สำเร็จ: ${_errorMessage(response)}');
  }

  static Future<Deposit> createDeposit(DepositRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: AuthToken.headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 201) {
      return Deposit.fromJson(json.decode(response.body));
    }
    throw Exception(_errorMessage(response));
  }

  static Future<Deposit> updateDeposit(String id, DepositRequest request) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$_endpoint/$id'),
      headers: AuthToken.headers,
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return Deposit.fromJson(json.decode(response.body));
    }
    throw Exception(_errorMessage(response));
  }

  static Future<void> deleteDeposit(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl$_endpoint/$id'), headers: AuthToken.headers);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_errorMessage(response));
  }
}
