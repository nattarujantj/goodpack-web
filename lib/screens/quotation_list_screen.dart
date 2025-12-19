import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quotation.dart';
import '../providers/quotation_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/responsive_layout.dart';

class QuotationListScreen extends StatefulWidget {
  final String? initialVatFilter;
  
  const QuotationListScreen({Key? key, this.initialVatFilter}) : super(key: key);

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  String _sortColumn = 'quotationDate';
  bool _sortAscending = false;
  String _statusFilter = 'ทั้งหมด';
  String _vatFilter = 'ทั้งหมด';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
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
    if (widget.initialVatFilter != null) {
      _vatFilter = widget.initialVatFilter!;
    }
    _initDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().loadQuotationsIfNeeded();
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
  void didUpdateWidget(QuotationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVatFilter != oldWidget.initialVatFilter) {
      setState(() {
        _vatFilter = widget.initialVatFilter ?? 'ทั้งหมด';
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
        title: 'รายการเสนอราคา',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/quotation-form'),
            tooltip: 'เพิ่มเสนอราคาใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<QuotationProvider>().loadQuotations(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<QuotationProvider>(
        builder: (context, quotationProvider, child) {
          if (quotationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (quotationProvider.error != null) {
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
                    quotationProvider.error!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => quotationProvider.loadQuotations(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredQuotations = _getFilteredQuotations(quotationProvider.quotations);
          final searchedQuotations = _getSearchedQuotations(filteredQuotations);
          final sortedQuotations = _getSortedQuotations(searchedQuotations);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(quotationProvider),

                // Quotation Count
                ResponsivePadding(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'แสดง ${sortedQuotations.length} จาก ${quotationProvider.quotations.length} รายการ',
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

                // Quotation Table
                sortedQuotations.isEmpty
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
                          _buildQuotationsTable(sortedQuotations),
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
                onPressed: () => context.push('/quotation-form'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเสนอราคา'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(QuotationProvider quotationProvider) {
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
                hintText: 'ค้นหารายการเสนอราคา...',
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

            // Status Filter
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    'สถานะ:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value!;
                      });
                    },
                    items: const [
                      DropdownMenuItem<String>(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                      DropdownMenuItem<String>(value: 'draft', child: Text('ร่าง')),
                      DropdownMenuItem<String>(value: 'sent', child: Text('ส่งแล้ว')),
                      DropdownMenuItem<String>(value: 'accepted', child: Text('ยอมรับ')),
                      DropdownMenuItem<String>(value: 'rejected', child: Text('ปฏิเสธ')),
                      DropdownMenuItem<String>(value: 'expired', child: Text('หมดอายุ')),
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

  Widget _buildQuotationsTable(List<Quotation> quotations) {
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
                      label: _buildSortableHeader('วันที่เสนอราคา', 'quotationDate'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('รหัสเสนอราคา', 'quotationCode'),
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
                      label: _buildSortableHeader('สถานะ', 'status'),
                    ),
                    DataColumn(
                      label: Container(
                        width: 100,
                        child: Text(
                          'รายการขาย',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
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
                  rows: quotations.map((quotation) {
                    return DataRow(
                      onSelectChanged: (_) => context.go('/quotation/${quotation.id}'),
                      cells: [
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              _formatDate(quotation.quotationDate),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 150,
                              child: Text(
                                quotation.quotationCode,
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
                                quotation.customerName,
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
                              quotation.contactName ?? '-',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: Text(
                              _getProductNames(quotation),
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              '฿${quotation.calculateGrandTotal().toStringAsFixed(2)}',
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
                                quotation.isVAT ? Icons.check_circle : Icons.cancel,
                                color: quotation.isVAT ? Colors.green : Colors.red,
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
                                  color: _getStatusColor(quotation.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  quotation.statusDisplay,
                                  style: TextStyle(
                                    color: _getStatusColor(quotation.status),
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
                            width: 100,
                            child: Center(
                              child: quotation.saleCode != null
                                  ? InkWell(
                                      onTap: () => _goToSale(quotation.saleCode!),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          quotation.saleCode!,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _createSaleFromQuotation(quotation),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'สร้าง',
                                        style: TextStyle(fontSize: 12),
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
                                  onTap: () => context.go('/quotation/${quotation.id}'),
                                  tooltip: 'ดูรายละเอียด',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.edit,
                                  onTap: () => context.push('/quotation-form?id=${quotation.id}'),
                                  tooltip: 'แก้ไข',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.copy,
                                  onTap: () => context.push('/quotation-form?duplicateId=${quotation.id}'),
                                  tooltip: 'คัดลอกรายการ',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.delete,
                                  onTap: () => _showDeleteDialog(quotation),
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
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบรายการเสนอราคาตามเงื่อนไขที่เลือก',
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

  void _showDeleteDialog(Quotation quotation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบรายการเสนอราคาของ "${quotation.customerName}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบรายการเสนอราคาเรียบร้อยแล้ว'),
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

  List<Quotation> _getFilteredQuotations(List<Quotation> quotations) {
    var filtered = quotations.toList();
    
    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((quotation) {
        final quotationDate = DateTime(quotation.quotationDate.year, quotation.quotationDate.month, quotation.quotationDate.day);
        return !quotationDate.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((quotation) {
        final quotationDate = DateTime(quotation.quotationDate.year, quotation.quotationDate.month, quotation.quotationDate.day);
        return !quotationDate.isAfter(_endDate!);
      }).toList();
    }
    
    // Filter by customer
    if (_selectedCustomerId != null) {
      filtered = filtered.where((quotation) => quotation.customerId == _selectedCustomerId).toList();
    }
    
    // Filter by status
    if (_statusFilter != 'ทั้งหมด') {
      filtered = filtered.where((quotation) => quotation.status == _statusFilter).toList();
    }
    
    // Filter by VAT
    if (_vatFilter != 'ทั้งหมด') {
      if (_vatFilter == 'VAT') {
        filtered = filtered.where((quotation) => quotation.isVAT).toList();
      } else if (_vatFilter == 'Non-VAT') {
        filtered = filtered.where((quotation) => !quotation.isVAT).toList();
      }
    }
    
    return filtered;
  }

  List<Quotation> _getSearchedQuotations(List<Quotation> quotations) {
    if (_searchQuery.isEmpty) return quotations;

    return quotations.where((quotation) {
      return quotation.quotationCode.toLowerCase().contains(_searchQuery) ||
             quotation.customerName.toLowerCase().contains(_searchQuery) ||
             (quotation.contactName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  List<Quotation> _getSortedQuotations(List<Quotation> quotations) {
    quotations.sort((a, b) {
      int comparison = 0;

      switch (_sortColumn) {
        case 'quotationCode':
          comparison = a.quotationCode.compareTo(b.quotationCode);
          break;
        case 'quotationDate':
          comparison = a.quotationDate.compareTo(b.quotationDate);
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
          comparison = a.calculateGrandTotal().compareTo(b.calculateGrandTotal());
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return quotations;
  }

  bool _hasActiveFilters() {
    return _statusFilter != 'ทั้งหมด' || 
           _vatFilter != 'ทั้งหมด' || 
           _searchQuery.isNotEmpty ||
           _startDate != null ||
           _endDate != null ||
           _selectedCustomerId != null;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'ทั้งหมด';
      _vatFilter = 'ทั้งหมด';
      _searchQuery = '';
      _searchController.clear();
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getProductNames(Quotation quotation) {
    if (quotation.items.isEmpty) return '-';
    
    // แสดงแค่ 3 รายการแรก
    final itemsToShow = quotation.items.take(3).toList();
    final names = itemsToShow.map((item) => item.productName).join('\n');
    
    // ถ้ามีมากกว่า 3 รายการ แสดง ... ต่อท้าย
    if (quotation.items.length > 3) {
      return '$names\n... (+${quotation.items.length - 3} รายการ)';
    }
    
    return names;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _createSaleFromQuotation(Quotation quotation) async {
    try {
      // Navigate to sale form with quotation ID for pre-filling
      context.push('/sale-form?quotationId=${quotation.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToSale(String saleCode) async {
    try {
      // Load sales to find the one with matching code
      await context.read<SaleProvider>().loadSales();
      
      // Find sale by code
      final sales = context.read<SaleProvider>().sales;
      final sale = sales.firstWhere(
        (s) => s.saleCode == saleCode,
        orElse: () => throw Exception('Sale not found'),
      );
      
      // Navigate to sale detail
      context.go('/sale/${sale.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบรายการขาย: $saleCode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
