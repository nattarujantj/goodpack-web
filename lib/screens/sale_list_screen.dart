import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../widgets/responsive_layout.dart';

class SaleListScreen extends StatefulWidget {
  final String? initialVatFilter;
  
  const SaleListScreen({Key? key, this.initialVatFilter}) : super(key: key);

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  String _sortColumn = 'saleDate';
  bool _sortAscending = false;
  String? _vatFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vatFilter = widget.initialVatFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }
  
  @override
  void didUpdateWidget(SaleListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVatFilter != oldWidget.initialVatFilter) {
      setState(() {
        _vatFilter = widget.initialVatFilter;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'รายการขาย',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/sale-form'),
            tooltip: 'เพิ่มรายการขายใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SaleProvider>().loadSales(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, child) {
          if (saleProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (saleProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  ResponsiveText(
                    saleProvider.error!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => saleProvider.loadSales(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredSales = _getFilteredSales(saleProvider.sales);
          final searchedSales = _getSearchedSales(filteredSales);
          final sortedSales = _getSortedSales(searchedSales);

          return SingleChildScrollView(
              child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(saleProvider),
                
                // Sale Count
                ResponsivePadding(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ResponsiveText(
                        'แสดง ${sortedSales.length} จาก ${saleProvider.sales.length} รายการ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                      if (_hasActiveFilters())
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('ล้างตัวกรอง'),
                  ),
                ],
              ),
                ),
                
                // Sale Table
                sortedSales.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Scroll indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
            children: [
                                Icon(Icons.swipe_left, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                ResponsiveText(
                                  'เลื่อนซ้าย-ขวาเพื่อดูคอลัมน์ทั้งหมด',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildSalesTable(sortedSales),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sale-form'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการขาย'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltersSection(SaleProvider saleProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
      padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหารายการขาย...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[400]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // VAT Filter
            Row(
        children: [
                Expanded(
                  child: ResponsiveText(
                    'ประเภท VAT:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
                    ),
            ),
          ),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String?>(
            value: _vatFilter,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _vatFilter = value;
                      });
                    },
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('ทั้งหมด')),
              DropdownMenuItem<String?>(value: 'vat', child: Text('VAT')),
              DropdownMenuItem<String?>(value: 'nonvat', child: Text('Non-VAT')),
            ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTable(List<Sale> sales) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              child: IntrinsicWidth(
        child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 2,
                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: [
            DataColumn(
                      label: _buildSortableHeader('วันที่ขาย', 'saleDate'),
            ),
            DataColumn(
                      label: _buildSortableHeader('รหัสรายการ', 'saleCode'),
            ),
            DataColumn(
                      label: _buildSortableHeader('ลูกค้า', 'customerName'),
            ),
            DataColumn(
                      label: _buildSortableHeader('ชื่อผู้ติดต่อ', 'contactName'),
            ),
            DataColumn(
                      label: Container(
                        width: 200,
                        child: Text(
                          'สินค้า',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
            ),
            DataColumn(
                      label: _buildSortableHeader('ยอดรวม', 'grandTotal'),
            ),
            DataColumn(
                      label: _buildSortableHeader('VAT', 'isVAT'),
            ),
            DataColumn(
                      label: _buildSortableHeader('สถานะการจ่าย', 'paymentStatus'),
            ),
            DataColumn(
                      label: Container(
                        width: 120,
                        child: Text(
                          'จัดการ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                  rows: sales.map((sale) {
            return DataRow(
              onSelectChanged: (_) => context.go('/sale/${sale.id}'),
              cells: [
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              _formatDate(sale.saleDate),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,
                            child: Text(
                              sale.saleCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: Text(
                              sale.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,
                            child: Text(
                              sale.contactName ?? '-',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: Text(
                              _getProductNames(sale),
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              '฿${_calculateGrandTotal(sale).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 80,
                            child: Center(
                              child: Icon(
                                sale.isVAT ? Icons.check_circle : Icons.cancel,
                                color: sale.isVAT ? Colors.green : Colors.red,
                                size: 20,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                            width: 100,
                            child: Center(
                              child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                                  color: sale.payment.isPaid ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.payment.isPaid ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
                      style: TextStyle(
                                    color: sale.payment.isPaid ? Colors.green[700] : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                          Container(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                _buildHoverIcon(
                                  icon: Icons.visibility,
                                  onTap: () => context.go('/sale/${sale.id}'),
                        tooltip: 'ดูรายละเอียด',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.copy,
                                  onTap: () => context.go('/sale-form?duplicateId=${sale.id}'),
                        tooltip: 'คัดลอกรายการ',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.edit,
                                  onTap: () => context.go('/sale-form?id=${sale.id}'),
                        tooltip: 'แก้ไข',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.delete,
                                  onTap: () => _showDeleteDialog(sale),
                        tooltip: 'ลบ',
                                  color: Colors.red,
                      ),
                    ],
                            ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortableHeader(String title, String sortKey) {
    final isSelected = _sortColumn == sortKey;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = sortKey;
            _sortAscending = true;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isSelected)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildHoverIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color ?? Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบรายการขายตามเงื่อนไขที่เลือก',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'ลองเปลี่ยนตัวกรองหรือคำค้นหา',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบรายการขายของ "${sale.customerName}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<SaleProvider>().deleteSale(sale.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบรายการขายเรียบร้อยแล้ว'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    if (_vatFilter == null) return sales;
    
    if (_vatFilter == 'vat') {
      return sales.where((sale) => sale.isVAT).toList();
    } else if (_vatFilter == 'nonvat') {
      return sales.where((sale) => !sale.isVAT).toList();
    }
    
    return sales;
  }

  List<Sale> _getSearchedSales(List<Sale> sales) {
    if (_searchQuery.isEmpty) return sales;
    
    return sales.where((sale) {
      return sale.saleCode.toLowerCase().contains(_searchQuery) ||
             sale.customerName.toLowerCase().contains(_searchQuery) ||
             (sale.contactName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  List<Sale> _getSortedSales(List<Sale> sales) {
    sales.sort((a, b) {
      int comparison = 0;
      
      switch (_sortColumn) {
        case 'saleCode':
          comparison = a.saleCode.compareTo(b.saleCode);
          break;
        case 'saleDate':
          comparison = a.saleDate.compareTo(b.saleDate);
          break;
        case 'customerName':
          comparison = a.customerName.compareTo(b.customerName);
          break;
        case 'contactName':
          comparison = (a.contactName ?? '').compareTo(b.contactName ?? '');
          break;
        case 'isVAT':
          comparison = a.isVAT.toString().compareTo(b.isVAT.toString());
          break;
        case 'grandTotal':
          comparison = _calculateGrandTotal(a).compareTo(_calculateGrandTotal(b));
          break;
        case 'paymentStatus':
          comparison = a.payment.isPaid.toString().compareTo(b.payment.isPaid.toString());
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sales;
  }

  bool _hasActiveFilters() {
    return _vatFilter != null || _searchQuery.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _vatFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }


  double _calculateGrandTotal(Sale sale) {
    final totalBeforeVAT = sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalVAT = sale.isVAT ? totalBeforeVAT * 0.07 : 0.0;
    return totalBeforeVAT + totalVAT + sale.shippingCost;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getProductNames(Sale sale) {
    if (sale.items.isEmpty) return '-';
    
    // แสดงแค่ 3 รายการแรก
    final itemsToShow = sale.items.take(3).toList();
    final names = itemsToShow.map((item) => item.productName).join('\n');
    
    // ถ้ามีมากกว่า 3 รายการ แสดง ... ต่อท้าย
    if (sale.items.length > 3) {
      return '$names\n... (+${sale.items.length - 3} รายการ)';
    }
    
    return names;
  }

}
