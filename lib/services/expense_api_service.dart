import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';
import '../config/app_config.dart';
import 'auth_token.dart';

class ExpenseApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _endpoint = '/expenses';

  static Future<List<Expense>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: AuthToken.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        if (response.statusCode == 404) return [];
        if (response.body.isEmpty || response.body == 'null') return [];

        final decoded = json.decode(response.body);
        if (decoded == null || decoded is! List) return [];

        return decoded.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading expenses: $e');
    }
  }

  static Future<Expense> getExpense(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: AuthToken.headers,
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading expense: $e');
    }
  }

  static Future<Expense> createExpense(ExpenseRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: AuthToken.headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating expense: $e');
    }
  }

  static Future<Expense> updateExpense(String id, ExpenseRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: AuthToken.headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  static Future<void> deleteExpense(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_endpoint/$id'),
        headers: AuthToken.headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/categories'),
        headers: AuthToken.headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.cast<String>();
        }
        return [];
      } else {
        return defaultCategories;
      }
    } catch (e) {
      return defaultCategories;
    }
  }

  static const List<String> defaultCategories = [
    'ค่าน้ำมัน',
    'ค่าเช่า',
    'เงินเดือน',
    'ค่าน้ำ',
    'ค่าไฟ',
    'ค่าโทรศัพท์/อินเทอร์เน็ต',
    'ค่าขนส่ง',
    'ค่าวัสดุสิ้นเปลือง',
    'ค่าซ่อมบำรุง',
    'อื่นๆ',
  ];
}
