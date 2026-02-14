import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_api_service.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _error = '';

  List<Customer> get allCustomers => _customers;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _customers.isNotEmpty;

  /// Load customers only if data is not already loaded
  Future<void> loadCustomersIfNeeded() async {
    if (_customers.isNotEmpty || _isLoading) return;
    await loadCustomers();
  }

  // Load all customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _customers = await CustomerApiService.getCustomers();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get customer by ID
  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ดึงลูกค้าจาก API ตาม ID (ใช้เมื่อเข้าลิงก์ตรงและยังไม่มีในแคช)
  Future<Customer?> fetchCustomerById(String id) async {
    try {
      final customer = await CustomerApiService.getCustomer(id);
      putCustomerInCache(customer);
      return customer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void putCustomerInCache(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    notifyListeners();
  }

  // Add new customer - returns Customer on success, null on failure
  Future<Customer?> addCustomer(CustomerRequest customerRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final newCustomer = await CustomerApiService.addCustomer(customerRequest);
      _customers.add(newCustomer);
      _error = '';
      return newCustomer;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update customer
  Future<bool> updateCustomer(String id, CustomerRequest customerRequest) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updatedCustomer = await CustomerApiService.updateCustomer(id, customerRequest);
      final index = _customers.indexWhere((customer) => customer.id == id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
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

  // Delete customer
  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await CustomerApiService.deleteCustomer(id);
      if (success) {
        _customers.removeWhere((customer) => customer.id == id);
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

  // Search customers
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    
    return _customers.where((customer) {
      return customer.companyName.toLowerCase().contains(query.toLowerCase()) ||
             customer.contactName.toLowerCase().contains(query.toLowerCase()) ||
             customer.customerCode.toLowerCase().contains(query.toLowerCase()) ||
             customer.taxId.toLowerCase().contains(query.toLowerCase()) ||
             customer.phone.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Clear search
  void clearSearch() {
    _error = '';
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadCustomers();
  }
}
