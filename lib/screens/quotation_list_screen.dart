import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quotation.dart';
import '../providers/quotation_provider.dart';
import '../providers/sale_provider.dart';
import '../widgets/responsive_layout.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({Key? key}) : super(key: key);

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  String _sortColumn = 'quotationDate';
  bool _sortAscending = false;
  String _statusFilter = 'ทั้งหมด';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().loadQuotations();
    });
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
            onPressed: () => context.go('/quotation-form'),
            tooltip: 'เพิ่มเสนอราคาใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<QuotationProvider>().loadQuotations(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<QuotationProvider>(
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
                        ],
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/quotation-form'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเสนอราคา'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltersSection(QuotationProvider quotationProvider) {
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
                            child: InkWell(
                              onTap: () => context.go('/quotation/${quotation.id}'),
                              child: Text(
                                quotation.quotationCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: InkWell(
                              onTap: () => context.go('/quotation/${quotation.id}'),
                              child: Text(
                                quotation.customerName,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.left,
                              ),
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
                                  onTap: () => context.go('/quotation-form?id=${quotation.id}'),
                                  tooltip: 'แก้ไข',
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
    if (_statusFilter == 'ทั้งหมด') return quotations;
    return quotations.where((quotation) => quotation.status == _statusFilter).toList();
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
    return _statusFilter != 'ทั้งหมด' || _searchQuery.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'ทั้งหมด';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
      context.go('/sale-form?quotationId=${quotation.id}');
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
