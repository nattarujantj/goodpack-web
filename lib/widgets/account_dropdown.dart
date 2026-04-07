import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'responsive_layout.dart';

class AccountDropdown extends StatelessWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool isRequired;

  const AccountDropdown({
    super.key,
    this.selectedAccountId,
    required this.onChanged,
    this.label = 'บัญชี *',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final configService = ConfigService();

    return FutureBuilder<void>(
      future: configService.isLoaded ? Future.value() : configService.loadConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLayout(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('กำลังโหลดบัญชี...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildLayout(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final accounts = configService.accounts;

        return _buildLayout(
          child: DropdownButtonFormField<String>(
            value: selectedAccountId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            hint: const Text('เลือกบัญชี'),
            items: accounts.map((account) {
              return DropdownMenuItem<String>(
                value: account.id,
                child: Text(account.displayName),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกบัญชี';
                    }
                    return null;
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildLayout({required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
