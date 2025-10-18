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

  Future<bool> addQuotation(QuotationRequest quotationRequest) async {
    try {
      final newQuotation = await _apiService.addQuotation(quotationRequest);
      _quotations.add(newQuotation);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
