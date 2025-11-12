import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/stock_adjustment.dart';

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

  // POST adjust stock
  Future<Product> adjustStock(String productId, StockAdjustmentRequest request) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.getProductByIdUrl(productId)}/stock/adjust'),
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        final errorBody = response.body;
        throw ApiException('Failed to adjust stock: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw ApiException('Error adjusting stock: $e');
    }
  }

  // GET stock history
  Future<List<StockAdjustment>> getStockHistory(
    String productId, {
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${AppConfig.getProductByIdUrl(productId)}/stock/history')
          .replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => StockAdjustment.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found');
      } else {
        throw ApiException('Failed to get stock history: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting stock history: $e');
    }
  }

  // DELETE stock adjustment
  Future<Product> deleteStockAdjustment(String adjustmentId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${AppConfig.baseUrl}/api/stock/adjustments/$adjustmentId'),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConfig.connectTimeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Stock adjustment not found');
      } else {
        throw ApiException('Failed to delete stock adjustment: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error deleting stock adjustment: $e');
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
