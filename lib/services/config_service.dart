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
  final String accountType;
  final bool isActive;

  AccountItem({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
    required this.accountType,
    required this.isActive,
  });

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      accountType: json['accountType'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  String get displayName => '$name ($accountNumber) - $bankName';
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
    if (kIsWeb) {
      // Check if we're running on web and not localhost
      final hostname = html.window.location.hostname;
      if (hostname != null && hostname != 'localhost' && hostname != '127.0.0.1') {
        // Running on mobile device or different host, try to use current host as API host
        EnvConfig.configureForMobile(hostname);
      } else {
        // Running on localhost
        EnvConfig.configureForDevelopment();
      }
    } else {
      // For non-web platforms, default to development or specific mobile config
      EnvConfig.configureForDevelopment(); // Or a specific mobile config if needed
    }
    // You can also load initial config from server here if needed
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
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/config/categories'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      _categories = jsonData.map((json) => ConfigItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  Future<void> _loadColors() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/config/colors'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      _colors = jsonData.map((json) => ConfigItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load colors: ${response.statusCode}');
    }
  }

  Future<void> _loadAccounts() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/config/accounts'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      _accounts = jsonData.map((json) => AccountItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load accounts: ${response.statusCode}');
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