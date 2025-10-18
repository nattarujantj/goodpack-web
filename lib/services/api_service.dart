import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET all products
  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.getProductsUrl()),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error loading products: $e');
    }
  }

  // GET product by ID
  Future<Product> getProductById(String id) async {
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.getProductByIdUrl(id)),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        throw ApiException('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error loading product: $e');
    }
  }

  // POST create new product
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _client
          .post(
            Uri.parse(AppConfig.getProductsUrl()),
            headers: _headers,
            body: json.encode(product.toJson()),
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error creating product: $e');
    }
  }

  // PUT update product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await _client
          .put(
            Uri.parse(AppConfig.getProductByIdUrl(id)),
            headers: _headers,
            body: json.encode(product.toJson()),
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        throw ApiException('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error updating product: $e');
    }
  }

  // DELETE product
  Future<void> deleteProduct(String id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(AppConfig.getProductByIdUrl(id)),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        throw ApiException('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error deleting product: $e');
    }
  }

  // PATCH update stock
  Future<Product> updateStock(String id, int newStock) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('${AppConfig.getProductByIdUrl(id)}/stock'),
            headers: _headers,
            body: json.encode({'stock': newStock}),
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        throw ApiException('Failed to update stock: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error updating stock: $e');
    }
  }

  // GET inventory report
  Future<List<Product>> getInventoryReport() async {
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.getInventoryUrl()),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to load inventory: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error loading inventory: $e');
    }
  }

  // GET QR code for product
  Future<String> getQrCodeData(String productId) async {
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.getQrCodeUrl(productId)),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['qrCodeData'] as String;
      } else {
        throw ApiException('Failed to get QR code: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting QR code: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
