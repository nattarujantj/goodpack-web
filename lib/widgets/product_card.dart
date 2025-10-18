import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildProductImage(),
              
              const SizedBox(height: 12),
              
              // Product Name
              ResponsiveText(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Product Description
              ResponsiveText(
                product.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // SKU ID and Code
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'SKU: ${product.skuId}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Code: ${product.code}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Color, Size, Category
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'สี: ${product.color}',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'ขนาด: ${product.size}',
                      Colors.teal,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Category
              _buildInfoChip(
                'หมวดหมู่: ${product.category}',
                Theme.of(context).primaryColor,
              ),
              
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
                  _buildStockIndicator(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'แก้ไข',
                    color: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'ลบ',
                    color: Colors.red[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 120,
      width: double.infinity,
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Icon(
        Icons.inventory_2,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ResponsiveText(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStockIndicator() {
    Color stockColor;
    String stockText;
    
    if (product.stock.actualStock == 0) {
      stockColor = Colors.red;
      stockText = 'หมด';
    } else if (product.isLowStock) {
      stockColor = Colors.orange;
      stockText = '${product.stock.actualStock} ชิ้น';
    } else {
      stockColor = Colors.green;
      stockText = '${product.stock.actualStock} ชิ้น';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stockColor.withOpacity(0.3)),
      ),
      child: ResponsiveText(
        stockText,
        style: TextStyle(
          color: stockColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
