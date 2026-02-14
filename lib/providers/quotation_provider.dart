import 'package:flutter/foundation.dart';
import '../models/quotation.dart';
import '../services/quotation_api_service.dart';

class QuotationProvider with ChangeNotifier {
  final QuotationApiService _apiService = QuotationApiService();

  List<Quotation> _quotations = [];
  bool _isLoading = false;
  String? _error;

  List<Quotation> get quotations => _quotations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _quotations.isNotEmpty;

  /// Load quotations only if data is not already loaded
  Future<void> loadQuotationsIfNeeded() async {
    if (_quotations.isNotEmpty || _isLoading) return;
    await loadQuotations();
  }

  Future<void> loadQuotations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quotations = await _apiService.getQuotations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Quotation?> addQuotation(QuotationRequest quotationRequest) async {
    try {
      final newQuotation = await _apiService.addQuotation(quotationRequest);
      _quotations.add(newQuotation);
      notifyListeners();
      return newQuotation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateQuotation(String id, QuotationRequest quotationRequest) async {
    try {
      final updatedQuotation = await _apiService.updateQuotation(id, quotationRequest);
      final index = _quotations.indexWhere((quotation) => quotation.id == id);
      if (index != -1) {
        _quotations[index] = updatedQuotation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuotation(String id) async {
    try {
      await _apiService.deleteQuotation(id);
      _quotations.removeWhere((quotation) => quotation.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Quotation? getQuotationById(String id) {
    try {
      return _quotations.firstWhere((quotation) => quotation.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ดึงเสนอราคาจาก API ตาม ID (ใช้เมื่อเข้าลิงก์ตรงและยังไม่มีในแคช)
  Future<Quotation?> fetchQuotationById(String id) async {
    try {
      final quotation = await _apiService.getQuotation(id);
      putQuotationInCache(quotation);
      return quotation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void putQuotationInCache(Quotation quotation) {
    final index = _quotations.indexWhere((q) => q.id == quotation.id);
    if (index >= 0) {
      _quotations[index] = quotation;
    } else {
      _quotations.add(quotation);
    }
    notifyListeners();
  }

  List<Quotation> getQuotationsByStatus(String status) {
    return _quotations.where((quotation) => quotation.status == status).toList();
  }

  Future<Map<String, dynamic>?> copyToSale(String id) async {
    try {
      return await _apiService.copyToSale(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update quotation status only
  /// Valid statuses: draft, sent, accepted, rejected, expired
  Future<bool> updateQuotationStatus(String id, String status) async {
    try {
      final updatedQuotation = await _apiService.updateQuotationStatus(id, status);
      final index = _quotations.indexWhere((quotation) => quotation.id == id);
      if (index != -1) {
        _quotations[index] = updatedQuotation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
