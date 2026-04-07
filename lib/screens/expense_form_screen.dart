import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../services/expense_api_service.dart';
import '../widgets/responsive_layout.dart';

class ExpenseFormScreen extends StatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({Key? key, this.expenseId}) : super(key: key);

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '';
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;
  bool _isEdit = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    _loadCategories();
    if (_isEdit) {
      _loadExpense();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await ExpenseApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (_selectedCategory.isEmpty && cats.isNotEmpty) {
          _selectedCategory = cats.first;
        }
      });
    }
  }

  Future<void> _loadExpense() async {
    final provider = context.read<ExpenseProvider>();
    var expense = provider.getExpenseById(widget.expenseId!);
    expense ??= await provider.fetchExpenseById(widget.expenseId!);

    if (expense != null && mounted) {
      setState(() {
        _selectedCategory = expense!.category;
        _descriptionController.text = expense.description;
        _amountController.text = expense.amount.toString();
        _notesController.text = expense.notes;
        _expenseDate = expense.expenseDate;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = ExpenseRequest(
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      expenseDate: DateFormat('yyyy-MM-dd').format(_expenseDate),
      notes: _notesController.text.trim(),
    );

    final provider = context.read<ExpenseProvider>();
    Expense? result;

    if (_isEdit) {
      result = await provider.updateExpense(widget.expenseId!, request);
    } else {
      result = await provider.createExpense(request);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'แก้ไขสำเร็จ' : 'เพิ่มค่าใช้จ่ายสำเร็จ')),
        );
        context.go('/expenses');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขค่าใช้จ่าย' : 'เพิ่มค่าใช้จ่าย',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/expenses');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('หมวดหมู่',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                if (_categories.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _categories.map((cat) {
                                      final isSelected = _selectedCategory == cat;
                                      return ChoiceChip(
                                        label: Text(cat),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() => _selectedCategory = cat);
                                          }
                                        },
                                        selectedColor:
                                            Theme.of(context).primaryColor.withOpacity(0.2),
                                      );
                                    }).toList(),
                                  )
                                else
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'รายละเอียด',
                                    hintText: 'เช่น ค่าน้ำมันรถส่งของ',
                                    prefixIcon: Icon(Icons.description),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'จำนวนเงิน (บาท) *',
                                    hintText: '0.00',
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'กรุณากรอกจำนวนเงิน';
                                    final amount = double.tryParse(v);
                                    if (amount == null || amount <= 0) {
                                      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'วันที่',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(_expenseDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'หมายเหตุ',
                                    hintText: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                                    prefixIcon: Icon(Icons.note),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/expenses');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('ยกเลิก'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _saveExpense,
                                icon: Icon(_isEdit ? Icons.save : Icons.add),
                                label: Text(_isEdit ? 'บันทึก' : 'เพิ่มค่าใช้จ่าย'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
