import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';
import '../widgets/inventory_item_card.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
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
        title: 'จัดการสต็อกสินค้า',
        actions: [
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

          return Column(
            children: [
              // Filters and Search
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
                    if (_hasActiveFilters())
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('ล้างตัวกรอง'),
                      ),
                  ],
                ),
              ),
              
              // Products List
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ResponsivePadding(
                        child: ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return InventoryItemCard(
                              product: filteredProducts[index],
                              onStockChanged: (newStock) => _updateStock(
                                filteredProducts[index],
                                newStock,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
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
            
            const SizedBox(height: 16),
            
            // Sort Options
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    'เรียงตาม:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
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

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || _selectedCategory != 'ทั้งหมด';
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'ทั้งหมด';
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

  Future<void> _updateStock(dynamic product, int newStock) async {
    if (newStock < 0) return;
    
    final success = await context.read<ProductProvider>().updateStock(product.id, newStock);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดตจำนวนสินค้า "${product.name}" เป็น $newStock ชิ้นเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
