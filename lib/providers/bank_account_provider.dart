import 'package:flutter/foundation.dart';
import '../models/bank_account.dart';

class BankAccountProvider with ChangeNotifier {
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = false;
  String? _error;

  List<BankAccount> get bankAccounts => _bankAccounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ดึงข้อมูลบัญชีธนาคารจาก server
  Future<void> loadBankAccounts() async {
    _setLoading(true);
    _error = null;

    try {
      _bankAccounts = await BankAccountService.getBankAccounts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // หาบัญชีธนาคารตาม ID
  BankAccount? getBankAccountById(String id) {
    try {
      return _bankAccounts.firstWhere((account) => account.id == id);
    } catch (e) {
      return null;
    }
  }

  // หาบัญชีธนาคารที่ active
  List<BankAccount> get activeBankAccounts {
    return _bankAccounts.where((account) => account.isActive).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
