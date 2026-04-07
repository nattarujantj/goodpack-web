import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/auth_token.dart';

class AuthProvider with ChangeNotifier {
  static const _tokenKey = 'jwt_token';

  AuthUser? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  String _error = '';

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      AuthToken.setToken(token);
      try {
        _user = await AuthService.getMe();
      } catch (_) {
        await _clearToken();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await AuthService.login(username, password);
      AuthToken.setToken(response.token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.token);

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    AuthToken.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
