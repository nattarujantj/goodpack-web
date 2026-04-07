import 'package:flutter/foundation.dart';
import '../models/international_import.dart';
import '../services/international_import_api_service.dart';

class InternationalImportProvider with ChangeNotifier {
  List<InternationalImport> _imports = [];
  bool _isLoading = false;
  String _error = '';

  List<InternationalImport> get allImports => _imports;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _imports.isNotEmpty;

  Future<void> loadIfNeeded() async {
    if (_imports.isNotEmpty || _isLoading) return;
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _imports = await InternationalImportApiService.getAll();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  InternationalImport? getById(String id) {
    try {
      return _imports.firstWhere((imp) => imp.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<InternationalImport?> fetchById(String id) async {
    try {
      final imp = await InternationalImportApiService.getById(id);
      _putInCache(imp);
      return imp;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _putInCache(InternationalImport imp) {
    final index = _imports.indexWhere((i) => i.id == imp.id);
    if (index >= 0) {
      _imports[index] = imp;
    } else {
      _imports.add(imp);
    }
    notifyListeners();
  }

  Future<InternationalImport?> create(InternationalImportRequest request) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final newImport = await InternationalImportApiService.create(request);
      _imports.add(newImport);
      _error = '';
      return newImport;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> update(String id, InternationalImportRequest request) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updated = await InternationalImportApiService.update(id, request);
      final index = _imports.indexWhere((imp) => imp.id == id);
      if (index != -1) {
        _imports[index] = updated;
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

  Future<bool> delete(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success = await InternationalImportApiService.delete(id);
      if (success) {
        _imports.removeWhere((imp) => imp.id == id);
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

  Future<Map<String, dynamic>?> createPurchaseFromImport(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await InternationalImportApiService.createPurchaseFromImport(id);
      // Refresh the import to get updated status
      await fetchById(id);
      _error = '';
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<InternationalImport> search(String query) {
    if (query.isEmpty) return _imports;
    final q = query.toLowerCase();
    return _imports.where((imp) {
      return imp.importCode.toLowerCase().contains(q) ||
          imp.supplierName.toLowerCase().contains(q) ||
          imp.shippingCompanyName.toLowerCase().contains(q) ||
          imp.items.any((item) =>
              item.productName.toLowerCase().contains(q) ||
              item.productCode.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> refresh() async {
    await load();
  }
}
