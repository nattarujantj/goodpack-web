class AuthToken {
  static String? _token;

  static String? get token => _token;

  static void setToken(String? token) {
    _token = token;
  }

  static void clear() {
    _token = null;
  }

  static Map<String, String> get headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  static Map<String, String> get authOnlyHeaders {
    final h = <String, String>{
      'Accept': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }
}
