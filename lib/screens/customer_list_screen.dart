import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';
  String _sortBy = 'companyName';
  bool _sortAscending = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
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
        title: 'รายการลูกค้า/ซัพพลายเออร์',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCustomerForm(),
            tooltip: 'เพิ่มลูกค้าใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CustomerProvider>().refresh(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (customerProvider.error.isNotEmpty) {
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
                    customerProvider.error,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => customerProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredCustomers = _getFilteredCustomers(customerProvider.allCustomers);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(customerProvider),
                
                // Customer Count
                ResponsivePadding(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'แสดง ${filteredCustomers.length} จาก ${customerProvider.allCustomers.length} รายการ',
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
                
                // Customer Table
                filteredCustomers.isEmpty
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
                          _buildCustomerTable(filteredCustomers),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCustomerForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มลูกค้า'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltersSection(CustomerProvider customerProvider) {
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
              hintText: 'ค้นหาลูกค้า...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTable(List<Customer> customers) {
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
                      label: _buildSortableHeader('รหัสลูกค้า', 'customerCode'),
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
                  rows: customers.map((customer) {
                    return DataRow(
                      onSelectChanged: (_) => _navigateToCustomerDetail(customer.id),
                      cells: [
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              customer.customerCode,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 200,
                            child: Text(
                              customer.companyName,
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
                              customer.contactName,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              customer.taxId,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 120,
                            child: Text(
                              customer.phone,
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
                                  onTap: () => _navigateToCustomerDetail(customer.id),
                                  tooltip: 'ดูรายละเอียด',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.edit,
                                  onTap: () => _navigateToCustomerForm(customer: customer),
                                  tooltip: 'แก้ไข',
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.copy,
                                  onTap: () => context.go('/customer-form?duplicateId=${customer.id}'),
                                  tooltip: 'คัดลอกลูกค้า',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 2),
                                _buildHoverIcon(
                                  icon: Icons.delete,
                                  onTap: () => _showDeleteDialog(customer),
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

  List<Customer> _getFilteredCustomers(List<Customer> customers) {
    List<Customer> filtered = List.from(customers);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.contactName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.customerCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.taxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'customerCode':
          comparison = a.customerCode.compareTo(b.customerCode);
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
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบลูกค้าตามเงื่อนไขที่เลือก',
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

  void _navigateToCustomerForm({Customer? customer}) {
    if (customer != null) {
      context.go('/customer-form?id=${customer.id}');
    } else {
      context.go('/customer-form');
    }
  }

  void _navigateToCustomerDetail(String customerId) {
    context.go('/customer/$customerId');
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบลูกค้า "${customer.companyName}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<CustomerProvider>().deleteCustomer(customer.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบลูกค้า "${customer.companyName}" เรียบร้อยแล้ว'),
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
