import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';

class InventoryItemCard extends StatelessWidget {
  final Product product;
  final Function(int) onStockChanged;

  const InventoryItemCard({
    Key? key,
    required this.product,
    required this.onStockChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            _buildProductImage(),
            
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: _buildProductInfo(),
            ),
            
            // Stock Controls
            _buildStockControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 80,
      height: 80,
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
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        
        // Category
        if (product.category != null) ...[
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Price
        ResponsiveText(
          product.formattedPrice,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStockControls() {
    return Column(
      children: [
        // Current Stock
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStockColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getStockColor().withOpacity(0.3)),
          ),
          child: ResponsiveText(
            '${product.stock.actualStock}',
            style: TextStyle(
              color: _getStockColor(),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Stock Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStockButton(
              icon: Icons.remove,
              color: Colors.red,
              onPressed: product.stock.actualStock > 0 ? () => onStockChanged(product.stock.actualStock - 1) : null,
            ),
            
            const SizedBox(width: 8),
            
            _buildStockButton(
              icon: Icons.add,
              color: Colors.green,
              onPressed: () => onStockChanged(product.stock.actualStock + 1),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Stock Status
        ResponsiveText(
          _getStockStatusText(),
          style: TextStyle(
            color: _getStockColor(),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStockButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: onPressed != null ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onPressed != null ? color.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? color : Colors.grey[400],
          size: 16,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Color _getStockColor() {
    if (product.stock.actualStock == 0) {
      return Colors.red;
    } else if (product.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStockStatusText() {
    if (product.stock.actualStock == 0) {
      return 'หมด';
    } else if (product.isLowStock) {
      return 'ใกล้หมด';
    } else {
      return 'ปกติ';
    }
  }
}
