import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/expense_api_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _error = '';

  List<Expense> get expenses => _expenses;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _expenses.isNotEmpty;

  Future<void> loadExpensesIfNeeded() async {
    if (_expenses.isNotEmpty || _isLoading) return;
    await loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _expenses = await ExpenseApiService.getExpenses();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await ExpenseApiService.getCategories();
      notifyListeners();
    } catch (e) {
      _categories = List.from(ExpenseApiService.defaultCategories);
    }
  }

  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Expense?> fetchExpenseById(String id) async {
    try {
      final expense = await ExpenseApiService.getExpense(id);
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _expenses[index] = expense;
      } else {
        _expenses.add(expense);
      }
      notifyListeners();
      return expense;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Expense?> createExpense(ExpenseRequest request) async {
    try {
      final expense = await ExpenseApiService.createExpense(request);
      _expenses.insert(0, expense);
      notifyListeners();
      return expense;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Expense?> updateExpense(String id, ExpenseRequest request) async {
    try {
      final expense = await ExpenseApiService.updateExpense(id, request);
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _expenses[index] = expense;
      }
      notifyListeners();
      return expense;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await ExpenseApiService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
