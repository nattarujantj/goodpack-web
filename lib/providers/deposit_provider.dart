import 'package:flutter/foundation.dart';
import '../models/deposit.dart';
import '../services/deposit_api_service.dart';

class DepositProvider with ChangeNotifier {
  List<Deposit> _deposits = [];
  bool _isLoading = false;
  bool _loaded = false;
  String _error = '';

  List<Deposit> get deposits => _deposits;
  bool get isLoading => _isLoading;
  bool get hasData => _loaded;
  String get error => _error;

  List<Deposit> depositsOfType(String type) =>
      _deposits.where((d) => d.type == type).toList();

  Future<void> loadDepositsIfNeeded() async {
    if (_loaded || _isLoading) return;
    await loadDeposits();
  }

  Future<void> loadDeposits() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _deposits = await DepositApiService.getDeposits();
      _loaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ให้หน้ารายการโหลดใหม่ครั้งถัดไป (เช่น หลังบันทึกรายการขาย/ซื้อที่หักมัดจำ)
  void invalidate() {
    _loaded = false;
  }

  Deposit? getById(String id) {
    for (final d in _deposits) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<Deposit> fetchById(String id) async {
    final deposit = await DepositApiService.getDeposit(id);
    _upsert(deposit);
    return deposit;
  }

  Future<Deposit> create(DepositRequest request) async {
    final deposit = await DepositApiService.createDeposit(request);
    _deposits.insert(0, deposit);
    notifyListeners();
    return deposit;
  }

  Future<Deposit> update(String id, DepositRequest request) async {
    final deposit = await DepositApiService.updateDeposit(id, request);
    _upsert(deposit);
    return deposit;
  }

  Future<void> delete(String id) async {
    await DepositApiService.deleteDeposit(id);
    _deposits.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void _upsert(Deposit deposit) {
    final index = _deposits.indexWhere((d) => d.id == deposit.id);
    if (index >= 0) {
      _deposits[index] = deposit;
    } else {
      _deposits.insert(0, deposit);
    }
    notifyListeners();
  }
}
