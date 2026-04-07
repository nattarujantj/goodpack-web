import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../utils/display_formatters.dart';
import 'searchable_dropdown.dart';

class SupplierDropdown extends StatelessWidget {
  final String? selectedSupplierId;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? hint;
  final bool allowClear;
  final bool isRequired;
  final Widget? prefixIcon;
  final Key? dropdownKey;

  const SupplierDropdown({
    super.key,
    this.selectedSupplierId,
    required this.onChanged,
    this.label = 'ซัพพลายเออร์ *',
    this.hint,
    this.allowClear = false,
    this.isRequired = true,
    this.prefixIcon,
    this.dropdownKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, supplierProvider, child) {
        if (supplierProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    prefixIcon ?? const Icon(Icons.local_shipping, color: Colors.grey),
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text('กำลังโหลดข้อมูลซัพพลายเออร์...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }

        final suppliers = supplierProvider.allSuppliers;

        return SearchableDropdown<String>(
          key: dropdownKey,
          value: selectedSupplierId,
          items: suppliers.map((s) => s.id).toList(),
          itemAsString: (id) {
            final supplier = suppliers.firstWhere(
              (s) => s.id == id,
              orElse: () => suppliers.first,
            );
            return formatSupplierDisplay(supplier);
          },
          onChanged: onChanged,
          hint: hint ?? (allowClear ? 'ทั้งหมด' : 'เลือกซัพพลายเออร์'),
          label: allowClear ? '$label (${suppliers.length})' : label,
          allowClear: allowClear,
          prefixIcon: prefixIcon ?? const Icon(Icons.local_shipping),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกซัพพลายเออร์';
                  }
                  return null;
                }
              : null,
        );
      },
    );
  }
}
