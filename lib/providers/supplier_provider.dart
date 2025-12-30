import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../services/supplier_api_service.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String _error = '';

  List<Supplier> get allSuppliers => _suppliers;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _suppliers.isNotEmpty;

  /// Load suppliers only if data is not already loaded
  Future<void> loadSuppliersIfNeeded() async {
    if (_suppliers.isNotEmpty || _isLoading) return;
    await loadSuppliers();
  }

  // Load all suppliers
  Future<void> loadSuppliers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _suppliers = await SupplierApiService.getSuppliers();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get supplier by ID
  Supplier? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((supplier) => supplier.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add new supplier - returns Supplier on success, null on failure
  Future<Supplier?> addSupplier(SupplierRequest supplierRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final newSupplier = await SupplierApiService.addSupplier(supplierRequest);
      _suppliers.add(newSupplier);
      _error = '';
      return newSupplier;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update supplier
  Future<bool> updateSupplier(String id, SupplierRequest supplierRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updatedSupplier = await SupplierApiService.updateSupplier(id, supplierRequest);
      final index = _suppliers.indexWhere((supplier) => supplier.id == id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
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

  // Delete supplier
  Future<bool> deleteSupplier(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await SupplierApiService.deleteSupplier(id);
      if (success) {
        _suppliers.removeWhere((supplier) => supplier.id == id);
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

  // Search suppliers
  List<Supplier> searchSuppliers(String query) {
    if (query.isEmpty) return _suppliers;
    
    return _suppliers.where((supplier) {
      return supplier.companyName.toLowerCase().contains(query.toLowerCase()) ||
             supplier.contactName.toLowerCase().contains(query.toLowerCase()) ||
             supplier.supplierCode.toLowerCase().contains(query.toLowerCase()) ||
             supplier.taxId.toLowerCase().contains(query.toLowerCase()) ||
             supplier.phone.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Clear search
  void clearSearch() {
    _error = '';
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadSuppliers();
  }
}

