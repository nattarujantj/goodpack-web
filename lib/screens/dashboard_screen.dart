import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/product_provider.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

  /// เดือนที่เลือกสำหรับดูสรุป (ใช้เฉพาะ year, month)
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSalesIfNeeded();
      context.read<PurchaseProvider>().loadPurchasesIfNeeded();
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _pickMonth() {
    final now = DateTime.now();
    showDialog<void>(
      context: context,
      builder: (context) {
        int year = _selectedMonth.year;
        int month = _selectedMonth.month;
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
                      items: List.generate(5, (i) => now.year - 4 + i)
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
                  child: const Text('ดูสรุป'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final canGoNext = _selectedMonth.isBefore(DateTime(now.year, now.month, 1));

    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'สรุปภาพรวม',
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                  });
                },
                tooltip: 'เดือนก่อน',
              ),
              InkWell(
                onTap: _pickMonth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Text(
                    '${_thaiMonths[_selectedMonth.month - 1]} ${_selectedMonth.year + 543}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isCurrentMonth ? null : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: canGoNext
                    ? () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                        });
                      }
                    : null,
                tooltip: 'เดือนถัดไป',
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer3<SaleProvider, PurchaseProvider, ProductProvider>(
        builder: (context, saleProvider, purchaseProvider, productProvider, child) {
          if (saleProvider.isLoading || purchaseProvider.isLoading || productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = saleProvider.sales;
          final purchases = purchaseProvider.allPurchases;
          final products = productProvider.allProducts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCards(sales, purchases, _selectedMonth),
                const SizedBox(height: 24),

                // Monthly Sales Chart
                _buildMonthlySalesChart(sales, _selectedMonth),
                const SizedBox(height: 24),

                // Two columns layout for desktop
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTopProfitProducts(sales, products, _selectedMonth)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTopSellingProducts(sales, _selectedMonth)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildTopProfitProducts(sales, products, _selectedMonth),
                          const SizedBox(height: 24),
                          _buildTopSellingProducts(sales, _selectedMonth),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Revenue vs Expense Chart
                _buildRevenueExpenseChart(sales, purchases, _selectedMonth),
                const SizedBox(height: 24),

                // Low Stock Alert
                _buildLowStockAlert(products, sales),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refreshData() {
    context.read<SaleProvider>().loadSales();
    context.read<PurchaseProvider>().loadPurchases();
    context.read<ProductProvider>().loadProducts();
  }

  // ==================== Summary Cards ====================
  Widget _buildSummaryCards(List<Sale> sales, List<Purchase> purchases, DateTime selectedMonth) {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);

    // Sales ในเดือนที่เลือก
    final thisMonthSales = sales.where((s) =>
      s.saleDate.year == selectedMonth.year && s.saleDate.month == selectedMonth.month
    ).toList();
    final thisMonthTotal = thisMonthSales.fold(0.0, (sum, s) => sum + _calculateSaleTotal(s));

    // Sales เดือนก่อน (เทียบเปรียบเทียบ)
    final lastMonthSales = sales.where((s) =>
      s.saleDate.year == prevMonth.year && s.saleDate.month == prevMonth.month
    ).toList();
    final lastMonthTotal = lastMonthSales.fold(0.0, (sum, s) => sum + _calculateSaleTotal(s));

    // ซื้อ ในเดือนที่เลือก
    final thisMonthPurchases = purchases.where((p) =>
      p.purchaseDate.year == selectedMonth.year && p.purchaseDate.month == selectedMonth.month
    ).toList();
    final thisMonthPurchaseTotal = thisMonthPurchases.fold(0.0, (sum, p) => sum + p.grandTotal);

    // Calculate growth percentage
    final growthPercent = lastMonthTotal > 0
        ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildSummaryCard(
              'ยอดขายเดือนที่เลือก',
              _formatCurrency(thisMonthTotal),
              Icons.trending_up,
              Colors.green,
              subtitle: '${thisMonthSales.length} รายการ',
              width: cardWidth,
            ),
            _buildSummaryCard(
              'เทียบเดือนก่อน',
              '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
              growthPercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              growthPercent >= 0 ? Colors.green : Colors.red,
              subtitle: _formatCurrency(lastMonthTotal),
              width: cardWidth,
            ),
            _buildSummaryCard(
              'ยอดซื้อเดือนที่เลือก',
              _formatCurrency(thisMonthPurchaseTotal),
              Icons.shopping_cart,
              Colors.blue,
              subtitle: '${thisMonthPurchases.length} รายการ',
              width: cardWidth,
            ),
            _buildSummaryCard(
              'กำไรขั้นต้น',
              _formatCurrency(thisMonthTotal - thisMonthPurchaseTotal),
              Icons.account_balance_wallet,
              Colors.orange,
              subtitle: 'รายได้ - รายจ่าย',
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle, double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== Monthly Sales Chart ====================
  Widget _buildMonthlySalesChart(List<Sale> sales, DateTime selectedMonth) {
    final chartYear = selectedMonth.year;
    final monthlyData = <int, double>{};

    for (int i = 1; i <= 12; i++) {
      monthlyData[i] = 0;
    }

    for (final sale in sales) {
      if (sale.saleDate.year == chartYear) {
        monthlyData[sale.saleDate.month] =
            (monthlyData[sale.saleDate.month] ?? 0) + _calculateSaleTotal(sale);
      }
    }

    final maxValue = monthlyData.values.fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'ยอดขายรายเดือน ปี ${chartYear + 543}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final value = monthlyData[month] ?? 0;
                  final height = maxValue > 0 ? (value / maxValue * 150) : 0.0;
                  final isSelectedMonth = month == selectedMonth.month;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (value > 0)
                            Text(
                              _formatShortCurrency(value),
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelectedMonth ? Colors.green : Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: height.clamp(4.0, 150.0),
                            decoration: BoxDecoration(
                              color: isSelectedMonth ? Colors.green : Colors.blue[300],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _thaiMonths[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelectedMonth ? FontWeight.bold : FontWeight.normal,
                              color: isSelectedMonth ? Colors.green : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Top Profit Products ====================
  Widget _buildTopProfitProducts(List<Sale> sales, List<Product> products, DateTime selectedMonth) {
    final monthSales = sales.where((s) =>
      s.saleDate.year == selectedMonth.year && s.saleDate.month == selectedMonth.month
    ).toList();
    final profitMap = <String, Map<String, dynamic>>{};

    for (final sale in monthSales) {
      for (final item in sale.items) {
        Product? product;
        try {
          product = products.firstWhere((p) => p.id == item.productId);
        } catch (e) {
          product = null;
        }
        
        // Estimate cost (use purchase price if available, or 70% of sale price)
        double costPerUnit = item.unitPrice * 0.7;
        if (product != null) {
          costPerUnit = product.price.purchaseVAT.latest > 0 
              ? product.price.purchaseVAT.latest 
              : item.unitPrice * 0.7;
        }
        final profit = (item.unitPrice - costPerUnit) * item.quantity;
          
        if (!profitMap.containsKey(item.productId)) {
          profitMap[item.productId] = {
            'name': item.productName,
            'profit': 0.0,
            'quantity': 0,
          };
        }
        profitMap[item.productId]!['profit'] += profit;
        profitMap[item.productId]!['quantity'] += item.quantity;
      }
    }

    final sortedProducts = profitMap.entries.toList()
      ..sort((a, b) => (b.value['profit'] as double).compareTo(a.value['profit'] as double));
    
    final top5 = sortedProducts.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Top 5 สินค้ากำไรดี',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (top5.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ไม่มีข้อมูล'),
              )
            else
              ...top5.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final profit = item.value['profit'] as double;
                final quantity = item.value['quantity'] as int;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMedalColor(index),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    item.value['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('ขายได้ $quantity ชิ้น'),
                  trailing: Text(
                    _formatCurrency(profit),
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ==================== Top Selling Products ====================
  Widget _buildTopSellingProducts(List<Sale> sales, DateTime selectedMonth) {
    final monthSales = sales.where((s) =>
      s.saleDate.year == selectedMonth.year && s.saleDate.month == selectedMonth.month
    ).toList();
    final yearSales = sales.where((s) => s.saleDate.year == selectedMonth.year).toList();

    final monthlyTop = _getTopProducts(monthSales, 5);
    final yearlyTop = _getTopProducts(yearSales, 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'สินค้าขายดี',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'เดือนที่เลือก',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (monthlyTop.isEmpty)
              const Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey))
            else
              ...monthlyTop.take(3).map((item) => _buildProductRankItem(item)),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ปี ${selectedMonth.year + 543}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (yearlyTop.isEmpty)
              const Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey))
            else
              ...yearlyTop.take(5).map((item) => _buildProductRankItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRankItem(MapEntry<String, Map<String, dynamic>> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.value['name'] as String,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${item.value['quantity']} ชิ้น',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, Map<String, dynamic>>> _getTopProducts(List<Sale> sales, int limit) {
    final quantityMap = <String, Map<String, dynamic>>{};
    
    for (final sale in sales) {
      for (final item in sale.items) {
        if (!quantityMap.containsKey(item.productId)) {
          quantityMap[item.productId] = {
            'name': item.productName,
            'quantity': 0,
          };
        }
        quantityMap[item.productId]!['quantity'] += item.quantity;
      }
    }

    final sorted = quantityMap.entries.toList()
      ..sort((a, b) => (b.value['quantity'] as int).compareTo(a.value['quantity'] as int));
    
    return sorted.take(limit).toList();
  }

  // ==================== Revenue vs Expense Chart ====================
  Widget _buildRevenueExpenseChart(List<Sale> sales, List<Purchase> purchases, DateTime selectedMonth) {
    final chartYear = selectedMonth.year;
    final monthlyData = <int, Map<String, double>>{};

    for (int i = 1; i <= 12; i++) {
      monthlyData[i] = {'revenue': 0, 'expense': 0};
    }

    for (final sale in sales) {
      if (sale.saleDate.year == chartYear) {
        monthlyData[sale.saleDate.month]!['revenue'] =
            (monthlyData[sale.saleDate.month]!['revenue'] ?? 0) + _calculateSaleTotal(sale);
      }
    }

    for (final purchase in purchases) {
      if (purchase.purchaseDate.year == chartYear) {
        monthlyData[purchase.purchaseDate.month]!['expense'] =
            (monthlyData[purchase.purchaseDate.month]!['expense'] ?? 0) + purchase.grandTotal;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'รายได้ vs รายจ่าย ปี ${chartYear + 543}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('รายได้', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('รายจ่าย', Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('เดือน')),
                  DataColumn(label: Text('รายได้'), numeric: true),
                  DataColumn(label: Text('รายจ่าย'), numeric: true),
                  DataColumn(label: Text('กำไร'), numeric: true),
                ],
                rows: List.generate(12, (index) {
                  final month = index + 1;
                  final revenue = monthlyData[month]!['revenue']!;
                  final expense = monthlyData[month]!['expense']!;
                  final profit = revenue - expense;
                  final isSelectedMonth = month == selectedMonth.month;

                  return DataRow(
                    cells: [
                      DataCell(Text(
                        _thaiMonths[index],
                        style: isSelectedMonth ? const TextStyle(fontWeight: FontWeight.bold) : null,
                      )),
                      DataCell(Text(_formatShortCurrency(revenue), style: const TextStyle(color: Colors.green))),
                      DataCell(Text(_formatShortCurrency(expense), style: const TextStyle(color: Colors.red))),
                      DataCell(Text(
                        _formatShortCurrency(profit),
                        style: TextStyle(
                          color: profit >= 0 ? Colors.blue : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ==================== Low Stock Alert ====================
  Widget _buildLowStockAlert(List<Product> products, List<Sale> sales) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    // Find products with orders in last 3 months
    final productOrderCount = <String, int>{};
    final productLastOrderQty = <String, int>{};
    
    for (final sale in sales) {
      if (sale.saleDate.isAfter(threeMonthsAgo)) {
        for (final item in sale.items) {
          productOrderCount[item.productId] = (productOrderCount[item.productId] ?? 0) + 1;
          productLastOrderQty[item.productId] = item.quantity;
        }
      }
    }

    // Filter products: 
    // - Has more than 2 orders in last 3 months
    // - Stock is less than last order quantity
    final lowStockProducts = products.where((p) {
      final orderCount = productOrderCount[p.id] ?? 0;
      final lastOrderQty = productLastOrderQty[p.id] ?? 0;
      final currentStock = p.stock.vat.remaining + p.stock.nonVAT.remaining;
      
      return orderCount >= 2 && currentStock < lastOrderQty && currentStock <= 5;
    }).toList();

    return Card(
      color: lowStockProducts.isNotEmpty ? Colors.red[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: lowStockProducts.isNotEmpty ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'สินค้าใกล้หมด (${lowStockProducts.length} รายการ)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: lowStockProducts.isNotEmpty ? Colors.red[700] : null,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (lowStockProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('ไม่มีสินค้าที่ใกล้หมด'),
                  ],
                ),
              )
            else
              ...lowStockProducts.map((p) {
                final currentStock = p.stock.vat.remaining + p.stock.nonVAT.remaining;
                final lastOrderQty = productLastOrderQty[p.id] ?? 0;
                final orderCount = productOrderCount[p.id] ?? 0;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(
                      '$currentStock',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text('ออเดอร์ล่าสุด: $lastOrderQty ชิ้น | สั่งซื้อ $orderCount ครั้งใน 3 เดือน'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ควรสั่งซื้อ',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ==================== Helper Methods ====================
  double _calculateSaleTotal(Sale sale) {
    final itemsTotal = sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    double vatAmount = 0.0;
    
    if (sale.isVAT) {
      if (sale.vatType == 'inclusive') {
        // VAT included in price
        vatAmount = 0;
      } else {
        vatAmount = itemsTotal * 0.07;
      }
    }
    
    return itemsTotal + vatAmount + sale.shippingCost;
  }

  String _formatCurrency(double value) {
    return '฿${value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}
