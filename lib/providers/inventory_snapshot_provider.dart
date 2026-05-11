import 'package:flutter/material.dart';
import '../models/inventory_snapshot.dart';
import '../services/inventory_snapshot_service.dart';

class InventorySnapshotProvider extends ChangeNotifier {
  List<InventorySnapshot> _snapshots = [];
  InventorySnapshot? _selectedSnapshot;
  bool _isLoading = false;
  String? _error;

  List<InventorySnapshot> get snapshots => _snapshots;
  InventorySnapshot? get selectedSnapshot => _selectedSnapshot;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSnapshots() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _snapshots = await InventorySnapshotService.getSnapshots();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSnapshot(int month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedSnapshot = await InventorySnapshotService.getSnapshot(month, year);
    } catch (e) {
      _error = e.toString();
      _selectedSnapshot = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> takeManualSnapshot(int month, int year) async {
    _isLoading = true;
    notifyListeners();

    final result = await InventorySnapshotService.takeManualSnapshot(month, year);
    final success = result['success'] == true;

    if (success) {
      _selectedSnapshot = InventorySnapshot.fromJson(result['data']);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateSnapshot(
    int month,
    int year,
    List<Map<String, dynamic>> products,
  ) async {
    _isLoading = true;
    notifyListeners();

    final result = await InventorySnapshotService.updateSnapshot(month, year, products);
    final success = result['success'] == true;

    if (success) {
      _selectedSnapshot = InventorySnapshot.fromJson(result['data']);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearSelectedSnapshot() {
    _selectedSnapshot = null;
    notifyListeners();
  }
}
