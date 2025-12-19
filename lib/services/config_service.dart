import 'dart:convert';
import 'dart:html' as html; // For web-specific checks
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/env_config.dart';

class ConfigItem {
  final String name;
  final String abbreviation;
  final String english;

  ConfigItem({
    required this.name,
    required this.abbreviation,
    required this.english,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      english: json['english'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'english': english,
    };
  }
}

class AccountItem {
  final String id;
  final String name;
  final String accountNumber;
  final String bankName;
  final bool isActive;

  AccountItem({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
    required this.isActive,
  });

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  // แสดงชื่อบัญชี: ถ้าไม่มีเลขบัญชี (เช่น เงินสด) แสดงแค่ชื่อธนาคาร
  String get displayName {
    if (accountNumber.isEmpty) {
      return bankName;
    }
    if (name.isEmpty) {
      return '$bankName ($accountNumber)';
    }
    return '$bankName - $name ($accountNumber)';
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  List<ConfigItem> _categories = [];
  List<ConfigItem> _colors = [];
  List<AccountItem> _accounts = [];
  bool _isLoaded = false;

  List<ConfigItem> get categories => _categories;
  List<ConfigItem> get colors => _colors;
  List<AccountItem> get accounts => _accounts;
  bool get isLoaded => _isLoaded;

  void initialize() {
    // Don't override dart-define settings - just load config
    // The API URL is already set via --dart-define=API_BASE_URL
    // Only configure runtime if dart-define is using default localhost value
    if (kIsWeb && EnvConfig.apiBaseUrl == 'http://localhost:8080/api') {
      // Check if we're running on web and not localhost
      final hostname = html.window.location.hostname;
      if (hostname != null && hostname != 'localhost' && hostname != '127.0.0.1') {
        // Running on production server, try to use current host as API host
        EnvConfig.configureForMobile(hostname);
      }
    }
    // Load config from server
    loadConfig();
  }

  // Manual configuration methods for debugging/testing
  void configureForMobile(String localIp) {
    EnvConfig.configureForMobile(localIp);
    loadConfig(); // Reload config with new API URL
  }

  void configureForDevelopment() {
    EnvConfig.configureForDevelopment();
    loadConfig(); // Reload config with new API URL
  }

  void configureForProduction() {
    EnvConfig.configureForProduction();
    loadConfig(); // Reload config with new API URL
  }

  Future<void> loadConfig() async {
    try {
      await Future.wait([
        _loadCategories(),
        _loadColors(),
        _loadAccounts(),
      ]);
      _isLoaded = true;
    } catch (e) {
      print('Error loading config: $e');
      _isLoaded = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/config/categories'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty && response.body != 'null') {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            _categories = decoded.map((json) => ConfigItem.fromJson(json)).toList();
          }
        }
      }
      // Don't throw on error, just keep empty list
    } catch (e) {
      print('Error loading categories: $e');
      // Keep empty list on error
    }
  }

  Future<void> _loadColors() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/config/colors'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty && response.body != 'null') {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            _colors = decoded.map((json) => ConfigItem.fromJson(json)).toList();
          }
        }
      }
      // Don't throw on error, just keep empty list
    } catch (e) {
      print('Error loading colors: $e');
      // Keep empty list on error
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/config/accounts'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty && response.body != 'null') {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            _accounts = decoded.map((json) => AccountItem.fromJson(json)).toList();
          }
        }
      }
      // Don't throw on error, just keep empty list
    } catch (e) {
      print('Error loading accounts: $e');
      // Keep empty list on error
    }
  }

  List<String> getCategoryNames() {
    return _categories.map((item) => item.name).toList();
  }

  List<String> getColorNames() {
    return _colors.map((item) => item.name).toList();
  }

  List<String> getAccountNames() {
    return _accounts.map((item) => item.displayName).toList();
  }

  String? getCategoryAbbreviation(String categoryName) {
    final item = _categories.firstWhere(
      (item) => item.name.toLowerCase() == categoryName.toLowerCase() ||
                item.english.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => ConfigItem(name: '', abbreviation: '', english: ''),
    );
    return item.abbreviation.isNotEmpty ? item.abbreviation : null;
  }

  String? getColorAbbreviation(String colorName) {
    final item = _colors.firstWhere(
      (item) => item.name.toLowerCase() == colorName.toLowerCase() ||
                item.english.toLowerCase() == colorName.toLowerCase(),
      orElse: () => ConfigItem(name: '', abbreviation: '', english: ''),
    );
    return item.abbreviation.isNotEmpty ? item.abbreviation : null;
  }

  void clear() {
    _categories.clear();
    _colors.clear();
    _isLoaded = false;
  }
}