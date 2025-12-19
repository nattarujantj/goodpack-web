import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/sale_api_service.dart';

class SaleProvider with ChangeNotifier {
  final SaleApiService _apiService = SaleApiService();
  
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _sales.isNotEmpty;

  /// Load sales only if data is not already loaded
  Future<void> loadSalesIfNeeded() async {
    if (_sales.isNotEmpty || _isLoading) return;
    await loadSales();
  }

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _apiService.getSales();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Sale?> addSale(SaleRequest saleRequest) async {
    try {
      final newSale = await _apiService.addSale(saleRequest);
      _sales.add(newSale);
      notifyListeners();
      return newSale;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSale(String id, SaleRequest saleRequest) async {
    try {
      final updatedSale = await _apiService.updateSale(id, saleRequest);
      final index = _sales.indexWhere((sale) => sale.id == id);
      if (index != -1) {
        _sales[index] = updatedSale;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(String id) async {
    try {
      await _apiService.deleteSale(id);
      _sales.removeWhere((sale) => sale.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Sale? getSaleById(String id) {
    try {
      return _sales.firstWhere((sale) => sale.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Sale> getSalesByVAT(bool isVAT) {
    return _sales.where((sale) => sale.isVAT == isVAT).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}
