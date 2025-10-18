class EnvConfig {
  // Runtime configuration - can be changed at runtime
  static String _apiHost = 'localhost';
  static String _apiPort = '8080';
  static String _apiProtocol = 'http';
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  
  static String get apiHost => _apiHost;
  static String get apiPort => _apiPort;
  static String get apiProtocol => _apiProtocol;

  // QR Code Configuration
  static const String qrBaseUrl = String.fromEnvironment(
    'QR_BASE_URL',
    defaultValue: 'https://goodpack.app',
  );
  
  static const String qrDomain = String.fromEnvironment(
    'QR_DOMAIN',
    defaultValue: 'goodpack.app',
  );

  // Development Configuration
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  // Network Configuration
  static const String webHost = String.fromEnvironment(
    'WEB_HOST',
    defaultValue: '0.0.0.0',
  );
  
  static const String webPort = String.fromEnvironment(
    'WEB_PORT',
    defaultValue: '3000',
  );

  // Placeholder Image
  static const String placeholderImageUrl = String.fromEnvironment(
    'PLACEHOLDER_IMAGE_URL',
    defaultValue: 'https://via.placeholder.com/400x300?text=Product+Image',
  );

  // Configuration methods
  static void configureForMobile(String localIp) {
    _apiHost = localIp;
    _apiPort = '8080';
    _apiProtocol = 'http';
  }

  static void configureForDevelopment() {
    _apiHost = 'localhost';
    _apiPort = '8080';
    _apiProtocol = 'http';
  }

  static void configureForProduction() {
    _apiHost = 'api.goodpack.app';
    _apiPort = '443';
    _apiProtocol = 'https';
  }

  // Helper methods
  static String get apiUrl => '$_apiProtocol://$_apiHost:$_apiPort/api';
  static String get qrCodeUrl => '$qrBaseUrl/product';
  static String get deepLinkUrl => '$qrBaseUrl/product';
}
