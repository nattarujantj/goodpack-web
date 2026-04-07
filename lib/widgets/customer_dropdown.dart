import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../utils/display_formatters.dart';
import 'searchable_dropdown.dart';

class CustomerDropdown extends StatelessWidget {
  final String? selectedCustomerId;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? hint;
  final bool allowClear;
  final bool isRequired;
  final Widget? prefixIcon;
  final Key? dropdownKey;

  const CustomerDropdown({
    super.key,
    this.selectedCustomerId,
    required this.onChanged,
    this.label = 'ลูกค้า *',
    this.hint,
    this.allowClear = false,
    this.isRequired = true,
    this.prefixIcon,
    this.dropdownKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        if (customerProvider.isLoading) {
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
                    prefixIcon ?? const Icon(Icons.person, color: Colors.grey),
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text('กำลังโหลดข้อมูลลูกค้า...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }

        final customers = customerProvider.allCustomers;

        return SearchableDropdown<String>(
          key: dropdownKey,
          value: selectedCustomerId,
          items: customers.map((c) => c.id).toList(),
          itemAsString: (id) {
            final customer = customers.firstWhere(
              (c) => c.id == id,
              orElse: () => customers.first,
            );
            return formatCustomerDisplay(customer);
          },
          onChanged: onChanged,
          hint: hint ?? (allowClear ? 'ทั้งหมด' : 'เลือกลูกค้า'),
          label: allowClear ? '$label (${customers.length})' : label,
          allowClear: allowClear,
          prefixIcon: prefixIcon ?? const Icon(Icons.person),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกลูกค้า';
                  }
                  return null;
                }
              : null,
        );
      },
    );
  }
}
