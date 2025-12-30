import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String _searchQuery = '';
  String _sortBy = 'supplierCode'; // เรียงตามรหัสซัพพลายเออร์เป็นค่าเริ่มต้น
  bool _sortAscending = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Draggable FAB position
  Offset _fabPosition = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
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
        title: 'รายการซัพพลายเออร์',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToSupplierForm(),
            tooltip: 'เพิ่มซัพพลายเออร์ใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SupplierProvider>().refresh(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<SupplierProvider>(
        builder: (context, supplierProvider, child) {
          if (supplierProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (supplierProvider.error.isNotEmpty) {
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
                    supplierProvider.error,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => supplierProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredSuppliers = _getFilteredSuppliers(supplierProvider.allSuppliers);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(supplierProvider),
                
                // Supplier Count
                ResponsivePadding(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'แสดง ${filteredSuppliers.length} จาก ${supplierProvider.allSuppliers.length} รายการ',
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
                
                // Supplier Table
                filteredSuppliers.isEmpty
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
                          _buildSupplierTable(filteredSuppliers),
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
                    (_fabPosition.dx - details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 150),
                    (_fabPosition.dy - details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 200),
                  );
                });
              },
              child: FloatingActionButton.extended(
        onPressed: () => _navigateToSupplierForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มซัพพลายเออร์'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(SupplierProvider supplierProvider) {
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
              hintText: 'ค้นหาซัพพลายเออร์...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierTable(List<Supplier> suppliers) {
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
                  headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                  columns: [
                    DataColumn(
                      label: _buildSortableHeader('รหัสซัพพลายเออร์', 'supplierCode'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('ชื่อบริษัท', 'companyName'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('ผู้ติดต่อ', 'contactName'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('เลขที่ผู้เสียภาษี', 'taxId'),
                    ),
                    DataColumn(
                      label: _buildSortableHeader('เบอร์โทร', 'phone'),
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
                  rows: suppliers.map((supplier) {
                    return DataRow(
                      onSelectChanged: (_) => _navigateToSupplierDetail(supplier.id),
                      cells: [
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              supplier.supplierCode,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                              child: Text(
                                supplier.companyName,
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
                              supplier.contactName,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              supplier.taxId,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              supplier.phone,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
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
                                  onTap: () => _navigateToSupplierDetail(supplier.id),
                                  tooltip: 'ดูรายละเอียด',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.edit,
                                  onTap: () => _navigateToSupplierForm(supplier: supplier),
                                  tooltip: 'แก้ไข',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.copy,
                                  onTap: () => context.push('/supplier-form?duplicateId=${supplier.id}'),
                                  tooltip: 'คัดลอกซัพพลายเออร์',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.delete,
                                  onTap: () => _showDeleteDialog(supplier),
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

  List<Supplier> _getFilteredSuppliers(List<Supplier> suppliers) {
    List<Supplier> filtered = List.from(suppliers);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((supplier) {
        return supplier.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.contactName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.supplierCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.taxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'supplierCode':
          comparison = a.supplierCode.compareTo(b.supplierCode);
          break;
        case 'companyName':
          comparison = a.companyName.compareTo(b.companyName);
          break;
        case 'contactName':
          comparison = a.contactName.compareTo(b.contactName);
          break;
        case 'taxId':
          comparison = a.taxId.compareTo(b.taxId);
          break;
        case 'phone':
          comparison = a.phone.compareTo(b.phone);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบซัพพลายเออร์ตามเงื่อนไขที่เลือก',
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

  void _navigateToSupplierForm({Supplier? supplier}) {
    if (supplier != null) {
      context.push('/supplier-form?id=${supplier.id}');
    } else {
      context.push('/supplier-form');
    }
  }

  void _navigateToSupplierDetail(String supplierId) {
    context.go('/supplier/$supplierId');
  }

  void _showDeleteDialog(Supplier supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบซัพพลายเออร์ "${supplier.companyName}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<SupplierProvider>().deleteSupplier(supplier.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบซัพพลายเออร์ "${supplier.companyName}" เรียบร้อยแล้ว'),
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

