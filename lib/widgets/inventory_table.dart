import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';

class InventoryTable extends StatelessWidget {
  final List<Product> products;
  final Function(String, bool) onSort;
  final String sortColumn;
  final bool sortAscending;

  const InventoryTable({
    Key? key,
    required this.products,
    required this.onSort,
    required this.sortColumn,
    required this.sortAscending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileView(),
      tablet: _buildTabletView(),
      desktop: _buildDesktopView(),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Image
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.category != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ResponsiveText(
                                product.category!,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Price and Stock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    _buildStockIndicator(product),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          _buildDataColumn('รูปภาพ', 'image'),
          _buildDataColumn('ชื่อสินค้า', 'name'),
          _buildDataColumn('หมวดหมู่', 'category'),
          _buildDataColumn('ราคา', 'price'),
          _buildDataColumn('จำนวนคงเหลือ', 'stock'),
        ],
        rows: products.map((product) => _buildDataRow(product)).toList(),
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          _buildDataColumn('รูปภาพ', 'image'),
          _buildDataColumn('ชื่อสินค้า', 'name'),
          _buildDataColumn('รายละเอียด', 'description'),
          _buildDataColumn('หมวดหมู่', 'category'),
          _buildDataColumn('ราคา', 'price'),
          _buildDataColumn('จำนวนคงเหลือ', 'stock'),
          _buildDataColumn('สถานะ', 'status'),
        ],
        rows: products.map((product) => _buildDataRow(product, isDesktop: true)).toList(),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, String columnId) {
    return DataColumn(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onSort: columnId != 'image' && columnId != 'status' 
          ? (columnIndex, ascending) => onSort(columnId, ascending)
          : null,
    );
  }

  DataRow _buildDataRow(Product product, {bool isDesktop = false}) {
    return DataRow(
      cells: [
        // Image
        DataCell(
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
        ),
        
        // Name
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        
        // Description (Desktop only)
        if (isDesktop)
          DataCell(
            SizedBox(
              width: 200,
              child: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        
        // Category
        DataCell(
          product.category != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.category!,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                )
              : const Text('-'),
        ),
        
        // Price
        DataCell(
          Text(
            product.formattedPrice,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        
        // Stock
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${product.stock}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildStockIndicator(product),
            ],
          ),
        ),
        
        // Status (Desktop only)
        if (isDesktop)
          DataCell(
            _buildStatusChip(product),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Icon(
      Icons.inventory_2,
      size: 20,
      color: Colors.grey[400],
    );
  }

  Widget _buildStockIndicator(Product product) {
    Color color;
    String text;
    
    if (product.stock == 0) {
      color = Colors.red;
      text = 'หมด';
    } else if (product.isLowStock) {
      color = Colors.orange;
      text = 'ใกล้หมด';
    } else {
      color = Colors.green;
      text = 'ปกติ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(Product product) {
    Color color;
    String text;
    IconData icon;
    
    if (product.stock == 0) {
      color = Colors.red;
      text = 'สินค้าหมด';
      icon = Icons.cancel;
    } else if (product.isLowStock) {
      color = Colors.orange;
      text = 'สินค้าใกล้หมด';
      icon = Icons.warning;
    } else {
      color = Colors.green;
      text = 'สินค้าปกติ';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
