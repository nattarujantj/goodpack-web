import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  String _sortBy = 'name';
  bool _sortAscending = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  
  // Multi-select functionality
  Set<String> _selectedProductIds = {};
  List<Product> _selectedProducts = [];
  
  // Scroll controllers for selected products table
  final ScrollController _selectedTableHorizontalScrollController = ScrollController();
  final ScrollController _selectedTableVerticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _selectedTableHorizontalScrollController.dispose();
    _selectedTableVerticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'รายการสินค้า',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToProductForm(),
            tooltip: 'เพิ่มสินค้าใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductProvider>().refresh(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (productProvider.error.isNotEmpty) {
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
                    productProvider.error,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => productProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _getFilteredProducts(productProvider.allProducts);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Selected Products Summary (if any selected)
                if (_selectedProducts.isNotEmpty) _buildSelectedProductsSection(),
                
                // Filters Section
                _buildFiltersSection(productProvider),
                
                // Product Count
                ResponsivePadding(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'แสดง ${filteredProducts.length} จาก ${productProvider.allProducts.length} รายการ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_selectedProductIds.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.clear, size: 16),
                              label: Text('ล้างการเลือก (${_selectedProductIds.length})'),
                            ),
                          if (_hasActiveFilters())
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('ล้างตัวกรอง'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Product Table
                filteredProducts.isEmpty
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
                          _buildProductTable(filteredProducts),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltersSection(ProductProvider productProvider) {
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
              hintText: 'ค้นหาสินค้า...',
            ),
            
            const SizedBox(height: 16),
            
            // Category Filter
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    'หมวดหมู่:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    items: [
                      'ทั้งหมด',
                      ...productProvider.categories,
                    ].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable(List<Product> products) {
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
              showCheckboxColumn: false,
            columns: [
              // Column สำหรับ Checkbox
              DataColumn(
                label: Container(
                  width: 40,
                  child: Checkbox(
                    value: _selectedProductIds.isNotEmpty,
                    tristate: true,
                    onChanged: (value) {
                      // Select all / Deselect all
                      setState(() {
                        if (_selectedProductIds.isEmpty) {
                          // Select all visible products
                          final allProducts = context.read<ProductProvider>().products;
                          _selectedProductIds = allProducts.map((p) => p.id).toSet();
                          _selectedProducts = List.from(allProducts);
                        } else {
                          // Deselect all
                          _selectedProductIds.clear();
                          _selectedProducts.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              DataColumn(
                label: _buildSortableHeader('ชื่อสินค้า', 'name'),
              ),
              DataColumn(
                label: _buildSortableHeader('รายละเอียด', 'details'),
              ),
              DataColumn(
                label: _buildSortableHeader('VAT\nคงเหลือ', 'vatRemaining'),
              ),
              DataColumn(
                label: _buildSortableHeader('Non-VAT\nคงเหลือ', 'nonVATRemaining'),
              ),
              DataColumn(
                label: _buildSortableHeader('Actual Stock', 'actualStock'),
              ),
              DataColumn(
                label: Container(
                  width: 100,
                  child: Text(
                    'จัดการ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            rows: products.map((product) {
              final isSelected = _selectedProductIds.contains(product.id);
              return DataRow(
                selected: isSelected,
                cells: [
                  // Checkbox cell
                  DataCell(
                    Container(
                      width: 40,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleProductSelection(product),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      width: 150,
                        child: Text(
                          product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    onTap: () => _navigateToProductDetail(product.id),
                  ),
                  DataCell(
                    Container(
                      width: 120, // กำหนดความกว้างของคอลัมน์รายละเอียด
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${product.category} - ${product.color}',
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            'ขนาด: ${product.size}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      width: 80, // กำหนดความกว้างของคอลัมน์ VAT
                      child: Text(
                        product.stock.vat.remaining.toString(),
                        style: TextStyle(
                          color: product.stock.vat.remaining < 0 ? Colors.red : null,
                          fontWeight: product.stock.vat.remaining < 0 ? FontWeight.bold : null,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      width: 80, // กำหนดความกว้างของคอลัมน์ Non-VAT
                      child: Text(
                        product.stock.nonVAT.remaining.toString(),
                        style: TextStyle(
                          color: product.stock.nonVAT.remaining < 0 ? Colors.red : null,
                          fontWeight: product.stock.nonVAT.remaining < 0 ? FontWeight.bold : null,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      width: 80, // กำหนดความกว้างของคอลัมน์ Actual Stock
                      child: Text(
                        product.stock.actualStock.toString(),
                        style: TextStyle(
                          color: product.stock.actualStock < 0 ? Colors.red : null,
                          fontWeight: product.stock.actualStock < 0 ? FontWeight.bold : null,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      width: 120, // กำหนดความกว้างของคอลัมน์จัดการ
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHoverIcon(
                            icon: Icons.visibility,
                            onTap: () => _navigateToProductDetail(product.id),
                            tooltip: 'ดูรายละเอียด',
                          ),
                          const SizedBox(width: 2),
                          _buildHoverIcon(
                            icon: Icons.edit,
                            onTap: () => _navigateToProductForm(product: product),
                            tooltip: 'แก้ไข',
                          ),
                          const SizedBox(width: 2),
                          _buildHoverIcon(
                            icon: Icons.copy,
                            onTap: () => context.go('/product-form?duplicateId=${product.id}'),
                            tooltip: 'คัดลอกสินค้า',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 2),
                          _buildHoverIcon(
                            icon: Icons.delete,
                            onTap: () => _showDeleteDialog(product),
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

  List<Product> _getFilteredProducts(List<Product> products) {
    List<Product> filtered = List.from(products);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.color.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.size.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'ทั้งหมด') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'details':
          // Sort by category first, then color, then size
          comparison = a.category.compareTo(b.category);
          if (comparison == 0) {
            comparison = a.color.compareTo(b.color);
            if (comparison == 0) {
              comparison = a.size.compareTo(b.size);
            }
          }
          break;
        case 'nonVATRemaining':
          comparison = a.stock.nonVAT.remaining.compareTo(b.stock.nonVAT.remaining);
          break;
        case 'vatRemaining':
          comparison = a.stock.vat.remaining.compareTo(b.stock.vat.remaining);
          break;
        case 'actualStock':
          comparison = a.stock.actualStock.compareTo(b.stock.actualStock);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || _selectedCategory != 'ทั้งหมด';
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'ทั้งหมด';
    });
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
        _selectedProducts.removeWhere((p) => p.id == product.id);
      } else {
        _selectedProductIds.add(product.id);
        _selectedProducts.add(product);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProductIds.clear();
      _selectedProducts.clear();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบสินค้าตามเงื่อนไขที่เลือก',
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

  void _navigateToProductForm({Product? product}) {
    if (product != null) {
      context.go('/product-form?id=${product.id}');
    } else {
      context.go('/product-form');
    }
  }

  void _navigateToProductDetail(String productId) {
    context.go('/product/$productId');
  }

  Widget _buildSelectedProductsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile layout - stack vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'สินค้าที่เลือก (${_selectedProducts.length} รายการ)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _exportSelected,
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('ส่งออก'),
                        ),
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('ล้างการเลือก'),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Desktop layout - horizontal
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'สินค้าที่เลือก (${_selectedProducts.length} รายการ)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _exportSelected,
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('ส่งออก'),
                        ),
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('ล้างการเลือก'),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
          // Selected products table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildSelectedProductsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductsTable() {
    const double headingHeight = 56.0; // Default DataTable heading height
    const double rowHeight = 48.0;    // Default DataRow height
    
    // Calculate number of rows to show (max 3)
    int numRowsToShow = _selectedProducts.length > 3 ? 3 : _selectedProducts.length;
    double tableHeight = headingHeight + (numRowsToShow * rowHeight);
    
    return SizedBox(
      height: tableHeight,
      child: Scrollbar(
        controller: _selectedTableVerticalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _selectedTableVerticalScrollController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: _selectedTableHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _selectedTableHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                columns: [
                  DataColumn(
                    label: Container(
                      width: 150,
                      child: const Text(
                        'ชื่อสินค้า',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 120,
                      child: const Text(
                        'รายละเอียด',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: const Text(
                        'VAT\nคงเหลือ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: const Text(
                        'Non-VAT\nคงเหลือ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: const Text(
                        'Actual Stock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 120,
                      child: const Text(
                        'จัดการ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                rows: _selectedProducts.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 150,
                            child: Text(
                              product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        onTap: () => _navigateToProductDetail(product.id),
                      ),
                      DataCell(
                        Container(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${product.category} - ${product.color}',
                                style: const TextStyle(fontSize: 15),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                'ขนาด: ${product.size}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          child: Text(
                            product.stock.vat.remaining.toString(),
                            style: TextStyle(
                              color: product.stock.vat.remaining < 0 ? Colors.red : null,
                              fontWeight: product.stock.vat.remaining < 0 ? FontWeight.bold : null,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          child: Text(
                            product.stock.nonVAT.remaining.toString(),
                            style: TextStyle(
                              color: product.stock.nonVAT.remaining < 0 ? Colors.red : null,
                              fontWeight: product.stock.nonVAT.remaining < 0 ? FontWeight.bold : null,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          child: Text(
                            product.stock.actualStock.toString(),
                            style: TextStyle(
                              color: product.stock.actualStock < 0 ? Colors.red : null,
                              fontWeight: product.stock.actualStock < 0 ? FontWeight.bold : null,
                              fontSize: 16,
                            ),
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
                                onTap: () => _navigateToProductDetail(product.id),
                                tooltip: 'ดูรายละเอียด',
                              ),
                              const SizedBox(width: 2),
                              _buildHoverIcon(
                                icon: Icons.edit,
                                onTap: () => _navigateToProductForm(product: product),
                                tooltip: 'แก้ไข',
                              ),
                              const SizedBox(width: 2),
                              _buildHoverIcon(
                                icon: Icons.remove_circle,
                                onTap: () => _toggleProductSelection(product),
                                tooltip: 'ลบออกจากการเลือก',
                                color: Colors.orange,
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

  void _exportSelected() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งออก ${_selectedProducts.length} รายการ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบสินค้า "${product.name}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context.read<ProductProvider>().deleteProduct(product.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบสินค้า "${product.name}" เรียบร้อยแล้ว'),
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
