import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/purchase_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _vatFilter = widget.initialVatFilter ?? 'ทั้งหมด';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
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
      body: Consumer<PurchaseProvider>(
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
                        ],
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToPurchaseForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการซื้อ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltersSection(PurchaseProvider purchaseProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
    return _searchQuery.isNotEmpty || _vatFilter != 'ทั้งหมด';
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _vatFilter = 'ทั้งหมด';
    });
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
