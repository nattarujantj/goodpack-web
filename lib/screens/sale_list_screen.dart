import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
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
  
  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Customer filter
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _vatFilter = widget.initialVatFilter;
    _initDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSalesIfNeeded();
      context.read<CustomerProvider>().loadCustomersIfNeeded();
    });
  }

  void _initDefaultDateRange() {
    final now = DateTime.now();
    // Default: first day of last month to today
    _startDate = DateTime(now.year, now.month - 1, 1);
    _endDate = now;
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            
            // Date Range Filter
            _buildDateRangeFilter(),
            
            const SizedBox(height: 16),
            
            // Customer Filter
            _buildCustomerFilter(),
            
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
                      DropdownMenuItem<String?>(value: 'VAT', child: Text('VAT')),
                      DropdownMenuItem<String?>(value: 'Non-VAT', child: Text('Non-VAT')),
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

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ช่วงวันที่:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('ล้าง'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isStart: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null 
                            ? _formatDateThai(_startDate!) 
                            : 'เริ่มต้น',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('ถึง'),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isStart: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null 
                            ? _formatDateThai(_endDate!) 
                            : 'สิ้นสุด',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Quick select buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickSelectChip('เดือนนี้', () {
              final now = DateTime.now();
              setState(() {
                _startDate = DateTime(now.year, now.month, 1);
                _endDate = now;
              });
            }),
            _buildQuickSelectChip('เดือนที่แล้ว', () {
              final now = DateTime.now();
              final lastMonth = DateTime(now.year, now.month - 1, 1);
              final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
              setState(() {
                _startDate = lastMonth;
                _endDate = lastDayOfLastMonth;
              });
            }),
            _buildQuickSelectChip('3 เดือนล่าสุด', () {
              final now = DateTime.now();
              setState(() {
                _startDate = DateTime(now.year, now.month - 2, 1);
                _endDate = now;
              });
            }),
            _buildQuickSelectChip('ปีนี้', () {
              final now = DateTime.now();
              setState(() {
                _startDate = DateTime(now.year, 1, 1);
                _endDate = now;
              });
            }),
            _buildQuickSelectChip('ปีที่แล้ว', () {
              final now = DateTime.now();
              setState(() {
                _startDate = DateTime(now.year - 1, 1, 1);
                _endDate = DateTime(now.year - 1, 12, 31);
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart 
        ? (_startDate ?? DateTime.now()) 
        : (_endDate ?? DateTime.now());
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('th', 'TH'),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is before start date, adjust it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          // If start date is after end date, adjust it
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  String _formatDateThai(DateTime date) {
    final thaiMonths = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${thaiMonths[date.month]} ${date.year + 543}';
  }

  Widget _buildCustomerFilter() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        final customers = customerProvider.allCustomers;
        
        return Row(
          children: [
            const Expanded(
              child: Text(
                'ลูกค้า:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: DropdownButton<String?>(
                value: _selectedCustomerId,
                isExpanded: true,
                hint: const Text('ทั้งหมด'),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                },
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('ทั้งหมด')),
                  ...customers.map((customer) => DropdownMenuItem<String?>(
                    value: customer.id,
                    child: Text(
                      customer.companyName.isNotEmpty 
                          ? customer.companyName 
                          : customer.contactName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
              ),
            ),
          ],
        );
      },
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
    var filtered = sales.toList();
    
    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((sale) {
        final saleDate = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
        return !saleDate.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((sale) {
        final saleDate = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
        return !saleDate.isAfter(_endDate!);
      }).toList();
    }
    
    // Filter by customer
    if (_selectedCustomerId != null) {
      filtered = filtered.where((sale) => sale.customerId == _selectedCustomerId).toList();
    }
    
    // Filter by VAT
    if (_vatFilter == 'VAT') {
      filtered = filtered.where((sale) => sale.isVAT).toList();
    } else if (_vatFilter == 'Non-VAT') {
      filtered = filtered.where((sale) => !sale.isVAT).toList();
    }
    
    return filtered;
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
    return _vatFilter != null || 
           _searchQuery.isNotEmpty || 
           _startDate != null ||
           _endDate != null ||
           _selectedCustomerId != null;
  }

  void _clearFilters() {
    setState(() {
      _vatFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedCustomerId = null;
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
