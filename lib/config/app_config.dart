import 'env_config.dart';

class AppConfig {
  // API Configuration
  static String get baseUrl => EnvConfig.apiUrl;
  static const String apiVersion = 'v1';
  
  // Endpoints
  static const String productsEndpoint = '/products';
  static const String inventoryEndpoint = '/inventory';
  static const String qrCodeEndpoint = '/qr-codes';
  
  // Timeout settings
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // QR Code settings
  static const int qrCodeSize = 200;
  static const String qrCodeErrorCorrectionLevel = 'M';
  
  // App settings
  static const String appName = 'GoodPack Inventory';
  static const String appVersion = '1.0.0';
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // Get full API URL
  static String getApiUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Get product specific endpoints
  static String getProductsUrl() => getApiUrl(productsEndpoint);
  static String getProductByIdUrl(String id) => '${getProductsUrl()}/$id';
  static String getInventoryUrl() => getApiUrl(inventoryEndpoint);
  static String getQrCodeUrl(String productId) => '${getApiUrl(qrCodeEndpoint)}/$productId';
}
