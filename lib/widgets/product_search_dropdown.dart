import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/display_formatters.dart';
import 'searchable_dropdown.dart';

class ProductSearchDropdown extends StatelessWidget {
  final Product? selectedProduct;
  final List<Product> products;
  final ValueChanged<Product?> onChanged;
  final bool enabled;
  final String label;
  final String? hint;
  final String? Function(Product?)? validator;
  final String Function(Product)? itemAsString;

  const ProductSearchDropdown({
    super.key,
    this.selectedProduct,
    required this.products,
    required this.onChanged,
    this.enabled = true,
    this.label = 'เลือกสินค้า *',
    this.hint,
    this.validator,
    this.itemAsString,
  });

  @override
  Widget build(BuildContext context) {
    return SearchableDropdown<Product>(
      value: selectedProduct,
      items: products,
      itemAsString: itemAsString ?? formatProductDisplay,
      enabled: enabled,
      onChanged: onChanged,
      hint: hint ?? 'เลือกสินค้า',
      label: label,
      validator: validator ??
          (value) {
            if (value == null) {
              return 'กรุณาเลือกสินค้า';
            }
            return null;
          },
      prefixIcon: const Icon(Icons.inventory),
    );
  }
}
