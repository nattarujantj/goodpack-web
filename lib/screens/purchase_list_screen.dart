import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/purchase_provider.dart';
import '../providers/customer_provider.dart';
import '../models/purchase.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';

class PurchaseListScreen extends StatefulWidget {
  final String? initialVatFilter;
  
  const PurchaseListScreen({Key? key, this.initialVatFilter}) : super(key: key);

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  String _searchQuery = '';
  String _sortBy = 'purchaseDate';
  bool _sortAscending = false; // Newest first
  late String _vatFilter;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  
  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Customer filter
  String? _selectedCustomerId;
  
  // Draggable FAB position
  Offset _fabPosition = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    _vatFilter = widget.initialVatFilter ?? 'ทั้งหมด';
    _initDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchasesIfNeeded();
      context.read<CustomerProvider>().loadCustomersIfNeeded();
    });
  }

  void _initDefaultDateRange() {
    final now = DateTime.now();
    // Default: first day of last month to last day of this month
    _startDate = DateTime(now.year, now.month - 1, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
  }
  
  @override
  void didUpdateWidget(PurchaseListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVatFilter != oldWidget.initialVatFilter) {
      setState(() {
        _vatFilter = widget.initialVatFilter ?? 'ทั้งหมด';
      });
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'รายการซื้อ',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToPurchaseForm(),
            tooltip: 'เพิ่มรายการซื้อใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PurchaseProvider>().refresh(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<PurchaseProvider>(
            builder: (context, purchaseProvider, child) {
              if (purchaseProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (purchaseProvider.error.isNotEmpty) {
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
                        purchaseProvider.error,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => purchaseProvider.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                );
              }

              final filteredPurchases = _getFilteredPurchases(purchaseProvider.allPurchases);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Filters Section
                    _buildFiltersSection(purchaseProvider),
                    
                    // Summary Section
                    _buildSummarySection(filteredPurchases),
                    
                    // Purchase Count
                    ResponsivePadding(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ResponsiveText(
                            'แสดง ${filteredPurchases.length} จาก ${purchaseProvider.allPurchases.length} รายการ',
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
                    
                    // Purchase Table
                    filteredPurchases.isEmpty
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
                              _buildPurchaseTable(filteredPurchases),
                              const SizedBox(height: 80), // Space for FAB
                            ],
                          ),
                  ],
                ),
              );
            },
          ),
          // Draggable FAB
          Positioned(
            right: _fabPosition.dx,
            bottom: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition = Offset(
                    (_fabPosition.dx - details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 180),
                    (_fabPosition.dy - details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 200),
                  );
                });
              },
              child: FloatingActionButton.extended(
                onPressed: () => _navigateToPurchaseForm(),
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มรายการซื้อ'),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(PurchaseProvider purchaseProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            SearchBar(
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              hintText: 'ค้นหารายการซื้อ...',
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
                  child: DropdownButton<String>(
                    value: _vatFilter,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _vatFilter = value!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                      DropdownMenuItem(value: 'VAT', child: Text('VAT')),
                      DropdownMenuItem(value: 'Non-VAT', child: Text('Non-VAT')),
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

  Widget _buildPurchaseTable(List<Purchase> purchases) {
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
                      label: _buildSortableHeader('วันที่ซื้อ', 'purchaseDate'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('รหัสรายการ', 'purchaseCode'),
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
                      label: _buildSortableHeader('ยอดรวม', 'totalAmount'),
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
                  rows: purchases.map((purchase) {
                    return DataRow(
                      onSelectChanged: (_) => _navigateToPurchaseDetail(purchase.id),
                      cells: [
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              _formatDate(purchase.purchaseDate),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,
                              child: Text(
                                purchase.purchaseCode,
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
                                purchase.customerName,
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
                              purchase.contactName ?? '-',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: Text(
                              _getProductNames(purchase),
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              '฿${purchase.grandTotal.toStringAsFixed(2)}',
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
                                purchase.isVAT ? Icons.check_circle : Icons.cancel,
                                color: purchase.isVAT ? Colors.green : Colors.red,
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
                                  color: purchase.payment.isPaid ? Colors.green[100] : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  purchase.payment.isPaid ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
                                  style: TextStyle(
                                    color: purchase.payment.isPaid ? Colors.green[700] : Colors.orange[700],
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
                                  onTap: () => _navigateToPurchaseDetail(purchase.id),
                                  tooltip: 'ดูรายละเอียด',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.edit,
                                  onTap: () => _navigateToPurchaseForm(purchase: purchase),
                                  tooltip: 'แก้ไข',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.copy,
                                  onTap: () => context.go('/purchase-form?duplicateId=${purchase.id}'),
                                  tooltip: 'คัดลอกรายการ',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.delete,
                                  onTap: () => _showDeleteDialog(purchase),
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
    final isSelected = _sortBy == sortKey;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
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

  List<Purchase> _getFilteredPurchases(List<Purchase> purchases) {
    List<Purchase> filtered = List.from(purchases);

    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((purchase) {
        final purchaseDate = DateTime(purchase.purchaseDate.year, purchase.purchaseDate.month, purchase.purchaseDate.day);
        return !purchaseDate.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((purchase) {
        final purchaseDate = DateTime(purchase.purchaseDate.year, purchase.purchaseDate.month, purchase.purchaseDate.day);
        return !purchaseDate.isAfter(_endDate!);
      }).toList();
    }

    // Filter by customer
    if (_selectedCustomerId != null) {
      filtered = filtered.where((purchase) => purchase.customerId == _selectedCustomerId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((purchase) {
        return purchase.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               purchase.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by VAT type
    if (_vatFilter != 'ทั้งหมด') {
      filtered = filtered.where((purchase) {
        if (_vatFilter == 'VAT') {
          return purchase.isVAT;
        } else if (_vatFilter == 'Non-VAT') {
          return !purchase.isVAT;
        }
        return true;
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'purchaseDate':
          comparison = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case 'purchaseCode':
          comparison = a.purchaseCode.compareTo(b.purchaseCode);
          break;
        case 'customerName':
          comparison = a.customerName.compareTo(b.customerName);
          break;
        case 'contactName':
          comparison = (a.contactName ?? '').compareTo(b.contactName ?? '');
          break;
        case 'itemCount':
          comparison = a.items.length.compareTo(b.items.length);
          break;
        case 'totalAmount':
          comparison = a.grandTotal.compareTo(b.grandTotal);
          break;
        case 'isVAT':
          comparison = a.isVAT.toString().compareTo(b.isVAT.toString());
          break;
        case 'paymentStatus':
          comparison = a.payment.isPaid.toString().compareTo(b.payment.isPaid.toString());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _vatFilter != 'ทั้งหมด' ||
           _startDate != null ||
           _endDate != null ||
           _selectedCustomerId != null;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _vatFilter = 'ทั้งหมด';
      _startDate = null;
      _endDate = null;
      _selectedCustomerId = null;
    });
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
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
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
        final isLoading = customerProvider.isLoading;
        
        return Row(
          children: [
            Expanded(
              child: Text(
                'ลูกค้า: ${isLoading ? "(กำลังโหลด...)" : "(${customers.length})"}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: isLoading 
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : DropdownButton<String?>(
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
                      ...customers.map((customer) {
                        final companyName = customer.companyName.isNotEmpty ? customer.companyName : 'ไม่มีชื่อบริษัท';
                        final contactName = customer.contactName.isNotEmpty ? customer.contactName : '';
                        final phoneNumber = customer.phone.isNotEmpty ? customer.phone : '';
                        final customerCode = customer.customerCode.isNotEmpty ? '[${customer.customerCode}]' : '';
                        
                        // Build display text: ชื่อบริษัท [รหัส] - ผู้ติดต่อ (เบอร์โทร)
                        String displayText = companyName;
                        if (customerCode.isNotEmpty) displayText += ' $customerCode';
                        if (contactName.isNotEmpty) displayText += ' - $contactName';
                        if (phoneNumber.isNotEmpty) displayText += ' ($phoneNumber)';
                        
                        return DropdownMenuItem<String?>(
                          value: customer.id,
                          child: Text(
                            displayText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummarySection(List<Purchase> purchases) {
    // Calculate totals
    double totalGrandAmount = 0.0;
    double totalPaid = 0.0;
    double totalUnpaid = 0.0;
    double totalVAT = 0.0;
    double totalBeforeVAT = 0.0;
    
    for (final purchase in purchases) {
      totalGrandAmount += purchase.grandTotal;
      totalVAT += purchase.totalVAT;
      totalBeforeVAT += purchase.totalAmount;
      
      if (purchase.payment.isPaid) {
        totalPaid += purchase.grandTotal;
      } else {
        totalUnpaid += purchase.grandTotal;
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'สรุปยอด (${purchases.length} รายการ)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Summary Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                
                if (isWide) {
                  // Desktop/Tablet: 2 rows
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryItem('ยอดก่อน VAT', totalBeforeVAT, Colors.grey[700]!)),
                          Expanded(child: _buildSummaryItem('VAT', totalVAT, Colors.orange[700]!)),
                          Expanded(child: _buildSummaryItem('ยอดรวมทั้งหมด', totalGrandAmount, Colors.blue[700]!)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryItem('จ่ายแล้ว', totalPaid, Colors.green[700]!)),
                          Expanded(child: _buildSummaryItem('ยังไม่จ่าย', totalUnpaid, Colors.red[700]!)),
                          Expanded(child: Container()), // Empty spacer
                        ],
                      ),
                    ],
                  );
                } else {
                  // Mobile: Stack vertically
                  return Column(
                    children: [
                      _buildSummaryItem('ยอดก่อน VAT', totalBeforeVAT, Colors.grey[700]!),
                      const SizedBox(height: 8),
                      _buildSummaryItem('VAT', totalVAT, Colors.orange[700]!),
                      const SizedBox(height: 8),
                      _buildSummaryItem('ยอดรวมทั้งหมด', totalGrandAmount, Colors.blue[700]!),
                      const Divider(height: 16),
                      _buildSummaryItem('จ่ายแล้ว', totalPaid, Colors.green[700]!),
                      const SizedBox(height: 8),
                      _buildSummaryItem('ยังไม่จ่าย', totalUnpaid, Colors.red[700]!),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '฿${_formatNumber(value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatNumber(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
            'ไม่พบรายการซื้อตามเงื่อนไขที่เลือก',
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

  void _navigateToPurchaseForm({Purchase? purchase}) {
    if (purchase != null) {
      context.go('/purchase-form?id=${purchase.id}');
    } else {
      context.go('/purchase-form');
    }
  }

  void _navigateToPurchaseDetail(String purchaseId) {
    context.go('/purchase/$purchaseId');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getProductNames(Purchase purchase) {
    if (purchase.items.isEmpty) return '-';
    
    // แสดงแค่ 3 รายการแรก
    final itemsToShow = purchase.items.take(3).toList();
    final names = itemsToShow.map((item) => item.productName).join('\n');
    
    // ถ้ามีมากกว่า 3 รายการ แสดง ... ต่อท้าย
    if (purchase.items.length > 3) {
      return '$names\n... (+${purchase.items.length - 3} รายการ)';
    }
    
    return names;
  }

  void _showDeleteDialog(Purchase purchase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบรายการซื้อของ "${purchase.customerName}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<PurchaseProvider>().deletePurchase(purchase.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบรายการซื้อเรียบร้อยแล้ว'),
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
}
