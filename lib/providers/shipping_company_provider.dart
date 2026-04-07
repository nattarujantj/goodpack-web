import 'package:flutter/foundation.dart';
import '../models/shipping_company.dart';
import '../services/shipping_company_api_service.dart';

class ShippingCompanyProvider with ChangeNotifier {
  List<ShippingCompany> _companies = [];
  bool _isLoading = false;
  String _error = '';

  List<ShippingCompany> get companies => _companies;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadIfNeeded() async {
    if (_companies.isNotEmpty || _isLoading) return;
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _companies = await ShippingCompanyApiService.getAll();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ShippingCompany?> create(ShippingCompanyRequest request) async {
    try {
      final company = await ShippingCompanyApiService.create(request);
      _companies.add(company);
      notifyListeners();
      return company;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(String id, ShippingCompanyRequest request) async {
    try {
      final updated = await ShippingCompanyApiService.update(id, request);
      final index = _companies.indexWhere((c) => c.id == id);
      if (index != -1) {
        _companies[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final success = await ShippingCompanyApiService.delete(id);
      if (success) {
        _companies.removeWhere((c) => c.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
