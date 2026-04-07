import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class VatFilterDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const VatFilterDropdown({
    super.key,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: ResponsiveText(
            'ประเภท VAT:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: DropdownButton<String?>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('ทั้งหมด')),
              DropdownMenuItem<String?>(value: 'VAT', child: Text('VAT')),
              DropdownMenuItem<String?>(value: 'Non-VAT', child: Text('Non-VAT')),
            ],
          ),
        ),
      ],
    );
  }
}
