import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';
import '../widgets/inventory_table.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  String _stockFilter = 'ทั้งหมด';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'รายงานสินค้าคงเหลือ',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductProvider>().refresh(),
            tooltip: 'รีเฟรช',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportReport(),
            tooltip: 'ส่งออกรายงาน',
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
          final summary = _calculateSummary(filteredProducts);

          return Column(
            children: [
              // Summary Cards
              _buildSummaryCards(summary),
              
              // Filters
              _buildFiltersSection(productProvider),
              
              // Report Table
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : InventoryTable(
                        products: filteredProducts.cast<Product>(),
                        onSort: (column, ascending) {
                          setState(() {
                            _sortBy = column;
                            _sortAscending = ascending;
                          });
                        },
                        sortColumn: _sortBy,
                        sortAscending: _sortAscending,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return ResponsivePadding(
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'สินค้าทั้งหมด',
              value: '${summary['totalProducts']}',
              icon: Icons.inventory_2,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'สินค้าคงเหลือ',
              value: '${summary['totalStock']}',
              icon: Icons.warehouse,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'สินค้าใกล้หมด',
              value: '${summary['lowStockProducts']}',
              icon: Icons.warning,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'สินค้าหมด',
              value: '${summary['outOfStockProducts']}',
              icon: Icons.cancel,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            ResponsiveText(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            
            // Filters Row
            Row(
              children: [
                // Category Filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'หมวดหมู่:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
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
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Stock Filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'สถานะสต็อก:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _stockFilter,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _stockFilter = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: 'ปกติ', child: Text('ปกติ')),
                          DropdownMenuItem(value: 'ใกล้หมด', child: Text('ใกล้หมด')),
                          DropdownMenuItem(value: 'หมด', child: Text('หมด')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Sort
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'เรียงตาม:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('ชื่อสินค้า')),
                          DropdownMenuItem(value: 'stock', child: Text('จำนวนคงเหลือ')),
                          DropdownMenuItem(value: 'price', child: Text('ราคา')),
                          DropdownMenuItem(value: 'category', child: Text('หมวดหมู่')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  tooltip: _sortAscending ? 'เรียงจากน้อยไปมาก' : 'เรียงจากมากไปน้อย',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    List<dynamic> filtered = List.from(products);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (product.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'ทั้งหมด') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Filter by stock status
    if (_stockFilter != 'ทั้งหมด') {
      filtered = filtered.where((product) {
        switch (_stockFilter) {
          case 'ปกติ':
            return product.stock > 10;
          case 'ใกล้หมด':
            return product.stock > 0 && product.stock <= 10;
          case 'หมด':
            return product.stock == 0;
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'category':
          comparison = (a.category ?? '').compareTo(b.category ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Map<String, dynamic> _calculateSummary(List<dynamic> products) {
    int totalProducts = products.length;
    int totalStock = products.fold(0, (sum, product) => sum + (product.stock.actualStock as int));
    int lowStockProducts = products.where((product) => product.isLowStock).length;
    int outOfStockProducts = products.where((product) => product.stock.actualStock.toInt() == 0).length;

    return {
      'totalProducts': totalProducts,
      'totalStock': totalStock,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'ไม่พบข้อมูลตามเงื่อนไขที่เลือก',
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

  void _exportReport() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์ส่งออกรายงานจะพร้อมใช้งานในอนาคต'),
      ),
    );
  }
}
