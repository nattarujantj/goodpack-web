import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/bank_account.dart';

class BankAccountService {
  static String get _baseUrl => '${EnvConfig.apiUrl}/bank-accounts';

  // Get bank account by ID
  static Future<BankAccount?> getBankAccountById(String accountId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$accountId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BankAccount.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Bank account not found
      } else {
        print('Error fetching bank account: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching bank account: $e');
      return null;
    }
  }

  // Get all bank accounts
  static Future<List<BankAccount>> getAllBankAccounts() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BankAccount.fromJson(json)).toList();
      } else {
        print('Error fetching bank accounts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
      return [];
    }
  }
}
