import 'package:flutter/foundation.dart';
import '../models/fcl_shipment.dart';
import '../services/fcl_shipment_api_service.dart';

class FclShipmentProvider with ChangeNotifier {
  List<FclShipment> _shipments = [];
  bool _isLoading = false;
  String _error = '';

  List<FclShipment> get allShipments => _shipments;
  List<FclShipment> get openShipments =>
      _shipments.where((s) => s.isOpen).toList();
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _shipments.isNotEmpty;

  Future<void> loadIfNeeded() async {
    if (_shipments.isNotEmpty || _isLoading) return;
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _shipments = await FclShipmentApiService.getAll();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  FclShipment? getById(String id) {
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<FclShipment?> fetchById(String id) async {
    try {
      final s = await FclShipmentApiService.getById(id);
      _putInCache(s);
      return s;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _putInCache(FclShipment s) {
    final index = _shipments.indexWhere((i) => i.id == s.id);
    if (index >= 0) {
      _shipments[index] = s;
    } else {
      _shipments.add(s);
    }
    notifyListeners();
  }

  Future<FclShipment?> create(FclShipmentRequest request) async {
    _error = '';
    try {
      final created = await FclShipmentApiService.create(request);
      _shipments.add(created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(String id, FclShipmentRequest request) async {
    _error = '';
    try {
      final updated = await FclShipmentApiService.update(id, request);
      _putInCache(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    _error = '';
    try {
      final ok = await FclShipmentApiService.delete(id);
      if (ok) {
        _shipments.removeWhere((s) => s.id == id);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> close(String id) async {
    _error = '';
    try {
      final updated = await FclShipmentApiService.close(id);
      _putInCache(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reopen(String id) async {
    _error = '';
    try {
      final updated = await FclShipmentApiService.reopen(id);
      _putInCache(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => load();
}
