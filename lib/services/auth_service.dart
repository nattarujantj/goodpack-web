import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_user.dart';
import 'auth_token.dart';

class AuthService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<LoginResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(json.decode(response.body));
    } else {
      final body = json.decode(response.body);
      throw AuthException(body['error'] ?? 'Login failed');
    }
  }

  static Future<AuthUser> getMe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: AuthToken.headers,
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode == 200) {
      return AuthUser.fromJson(json.decode(response.body));
    } else {
      throw AuthException('Session expired');
    }
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: AuthToken.headers,
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw AuthException(body['error'] ?? 'Failed to change password');
    }
  }

  static Future<AuthUser> register(String username, String password, String displayName, String role) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: AuthToken.headers,
      body: json.encode({
        'username': username,
        'password': password,
        'display_name': displayName,
        'role': role,
      }),
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode == 201) {
      return AuthUser.fromJson(json.decode(response.body));
    } else {
      final body = json.decode(response.body);
      throw AuthException(body['error'] ?? 'Failed to register user');
    }
  }

  static Future<List<AuthUser>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/users'),
      headers: AuthToken.headers,
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((j) => AuthUser.fromJson(j)).toList();
    } else {
      throw AuthException('Failed to fetch users');
    }
  }

  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/auth/users?id=$userId'),
      headers: AuthToken.headers,
    ).timeout(Duration(milliseconds: AppConfig.connectTimeout));

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw AuthException(body['error'] ?? 'Failed to delete user');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
