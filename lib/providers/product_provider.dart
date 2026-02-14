import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_adjustment.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;

  // Initialize and load products
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _products = await _apiService.getProducts();
      _filteredProducts = List.from(_products);
      notifyListeners();
    } catch (e) {
      _setError('ไม่สามารถโหลดข้อมูลสินค้าได้: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.description.toLowerCase().contains(query.toLowerCase()) ||
               (product.category?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    
    notifyListeners();
  }

  // Add new product
  Future<Product?> addProduct(Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      final newProduct = await _apiService.createProduct(product);
      _products.add(newProduct);
      _filteredProducts = List.from(_products);
      notifyListeners();
      return newProduct;
    } catch (e) {
      _setError('ไม่สามารถเพิ่มสินค้าได้: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedProduct = await _apiService.updateProduct(product.id, product);
      
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('ไม่สามารถอัปเดตสินค้าได้: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      _filteredProducts = List.from(_products);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('ไม่สามารถลบสินค้าได้: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update stock
  Future<bool> updateStock(String productId, int newStock) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedProduct = await _apiService.updateStock(productId, newStock);
      
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('ไม่สามารถอัปเดตจำนวนสินค้าได้: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ดึงสินค้าจาก API ตาม ID (ใช้เมื่อเข้าลิงก์ตรงและยังไม่มีในแคช)
  Future<Product?> fetchProductById(String id) async {
    try {
      final product = await _apiService.getProductById(id);
      putProductInCache(product);
      return product;
    } catch (e) {
      _setError('ไม่สามารถโหลดข้อมูลสินค้าได้: $e');
      return null;
    }
  }

  void putProductInCache(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Get low stock products
  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  // Get all categories
  List<String> get categories {
    final categorySet = _products
        .where((product) => product.category != null)
        .map((product) => product.category!)
        .toSet();
    return categorySet.toList()..sort();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadProducts();
  }

  // Adjust stock
  Future<bool> adjustStock(
    String productId,
    String adjustmentType,
    String stockType,
    int quantity, {
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final request = StockAdjustmentRequest(
        adjustmentType: adjustmentType,
        stockType: stockType,
        quantity: quantity,
        notes: notes,
      );

      final updatedProduct = await _apiService.adjustStock(productId, request);

      // Update product in list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('ไม่สามารถแก้ไขสต็อกได้: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get stock history
  Future<List<StockAdjustment>> getStockHistory(
    String productId, {
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final history = await _apiService.getStockHistory(
        productId,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      return history;
    } catch (e) {
      _setError('ไม่สามารถโหลดประวัติสต็อกได้: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Delete stock adjustment
  Future<bool> deleteStockAdjustment(String adjustmentId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProduct = await _apiService.deleteStockAdjustment(adjustmentId);

      // Update product in list
      final index = _products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('ไม่สามารถลบรายการแก้ไขสต็อกได้: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = '';
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
