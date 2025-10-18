import 'package:flutter/foundation.dart';
import '../models/purchase.dart';
import '../services/purchase_api_service.dart';

class PurchaseProvider with ChangeNotifier {
  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String _error = '';

  List<Purchase> get allPurchases => _purchases;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load all purchases
  Future<void> loadPurchases() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _purchases = await PurchaseApiService.getPurchases();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get purchase by ID
  Purchase? getPurchaseById(String id) {
    try {
      return _purchases.firstWhere((purchase) => purchase.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add new purchase
  Future<bool> addPurchase(PurchaseRequest purchaseRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final newPurchase = await PurchaseApiService.addPurchase(purchaseRequest);
      _purchases.add(newPurchase);
      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update purchase
  Future<bool> updatePurchase(String id, PurchaseRequest purchaseRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updatedPurchase = await PurchaseApiService.updatePurchase(id, purchaseRequest);
      final index = _purchases.indexWhere((purchase) => purchase.id == id);
      if (index != -1) {
        _purchases[index] = updatedPurchase;
      }
      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete purchase
  Future<bool> deletePurchase(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await PurchaseApiService.deletePurchase(id);
      if (success) {
        _purchases.removeWhere((purchase) => purchase.id == id);
      }
      _error = '';
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search purchases
  List<Purchase> searchPurchases(String query) {
    if (query.isEmpty) return _purchases;
    
    return _purchases.where((purchase) {
      return purchase.customerName.toLowerCase().contains(query.toLowerCase()) ||
             purchase.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Clear search
  void clearSearch() {
    _error = '';
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadPurchases();
  }
}
