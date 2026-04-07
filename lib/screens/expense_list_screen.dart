import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../widgets/responsive_layout.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'ทั้งหมด';
  DateTime? _selectedMonth;
  final _currencyFormat = NumberFormat('#,##0.00', 'th');

  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpensesIfNeeded();
    });
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    var filtered = expenses.where((e) {
      if (_selectedMonth != null) {
        if (e.expenseDate.year != _selectedMonth!.year ||
            e.expenseDate.month != _selectedMonth!.month) {
          return false;
        }
      }
      if (_categoryFilter != 'ทั้งหมด' && e.category != _categoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return e.category.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.notes.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'ค่าใช้จ่าย',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ExpenseProvider>().loadExpenses(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filterExpenses(provider.expenses);
          final totalAmount = filtered.fold(0.0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              _buildFilters(provider.expenses),
              _buildSummaryBar(totalAmount, filtered.length),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('ไม่มีรายการค่าใช้จ่าย',
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadExpenses(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildExpenseCard(filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/expense-form'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(List<Expense> allExpenses) {
    final categories = <String>{'ทั้งหมด'};
    for (final e in allExpenses) {
      categories.add(e.category);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                        _selectedMonth!.year, _selectedMonth!.month - 1, 1);
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickMonth,
                  child: Text(
                    '${_thaiMonths[_selectedMonth!.month - 1]} ${_selectedMonth!.year + 543}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                        _selectedMonth!.year, _selectedMonth!.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหา...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _categoryFilter,
                isDense: true,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _categoryFilter = v ?? 'ทั้งหมด'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(double total, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$count รายการ',
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(
            'รวม ฿${_currencyFormat.format(total)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final dateStr = DateFormat('dd/MM/yyyy').format(expense.expenseDate);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ลบรายการค่าใช้จ่าย'),
            content: Text('ต้องการลบ "${expense.category}${expense.description.isNotEmpty ? ' - ${expense.description}' : ''}" ใช่ไหม?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('ลบ'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => _deleteWithUndo(expense),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ลบ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(expense.category).withOpacity(0.15),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 20,
            ),
          ),
          title: Text(
            expense.category,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expense.description.isNotEmpty)
                Text(expense.description, style: const TextStyle(fontSize: 12)),
              Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '฿${_currencyFormat.format(expense.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => _deleteWithConfirmation(expense),
                tooltip: 'ลบ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          onTap: () => context.go('/expense-form?id=${expense.id}'),
        ),
      ),
    );
  }

  void _deleteWithConfirmation(Expense expense) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการค่าใช้จ่าย'),
        content: Text('ต้องการลบ "${expense.category}${expense.description.isNotEmpty ? ' - ${expense.description}' : ''}" ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteWithUndo(expense);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _deleteWithUndo(Expense expense) {
    final provider = context.read<ExpenseProvider>();
    provider.deleteExpense(expense.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบ "${expense.category}" แล้ว'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ยกเลิก (Undo)',
          textColor: Colors.yellow,
          onPressed: () {
            provider.createExpense(ExpenseRequest(
              category: expense.category,
              description: expense.description,
              amount: expense.amount,
              expenseDate: DateFormat('yyyy-MM-dd').format(expense.expenseDate),
              notes: expense.notes,
            ));
          },
        ),
      ),
    );
  }

  void _pickMonth() {
    showDialog<void>(
      context: context,
      builder: (context) {
        int year = _selectedMonth!.year;
        int month = _selectedMonth!.month;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เลือกเดือน'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ปี พ.ศ.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: year,
                      isExpanded: true,
                      items: List.generate(5, (i) => DateTime.now().year - 4 + i)
                          .map((y) => DropdownMenuItem(value: y, child: Text('${y + 543}')))
                          .toList(),
                      onChanged: (v) => setDialogState(() => year = v ?? year),
                    ),
                    const SizedBox(height: 16),
                    const Text('เดือน', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        final m = i + 1;
                        final isSelected = month == m;
                        return InkWell(
                          onTap: () => setDialogState(() => month = m),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(_thaiMonths[i]),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() => _selectedMonth = DateTime(year, month, 1));
                    Navigator.of(context).pop();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'ค่าน้ำมัน': return Icons.local_gas_station;
      case 'ค่าเช่า': return Icons.home;
      case 'เงินเดือน': return Icons.people;
      case 'ค่าน้ำ': return Icons.water_drop;
      case 'ค่าไฟ': return Icons.bolt;
      case 'ค่าโทรศัพท์/อินเทอร์เน็ต': return Icons.wifi;
      case 'ค่าขนส่ง': return Icons.local_shipping;
      case 'ค่าวัสดุสิ้นเปลือง': return Icons.build;
      case 'ค่าซ่อมบำรุง': return Icons.construction;
      default: return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ค่าน้ำมัน': return Colors.amber.shade700;
      case 'ค่าเช่า': return Colors.blue.shade700;
      case 'เงินเดือน': return Colors.green.shade700;
      case 'ค่าน้ำ': return Colors.cyan.shade700;
      case 'ค่าไฟ': return Colors.yellow.shade800;
      case 'ค่าโทรศัพท์/อินเทอร์เน็ต': return Colors.purple.shade700;
      case 'ค่าขนส่ง': return Colors.brown.shade600;
      case 'ค่าวัสดุสิ้นเปลือง': return Colors.teal.shade700;
      case 'ค่าซ่อมบำรุง': return Colors.deepOrange.shade700;
      default: return Colors.grey.shade700;
    }
  }
}
