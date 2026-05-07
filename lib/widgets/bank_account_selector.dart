import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';
import 'searchable_dropdown.dart';

class BankAccountSelector extends StatefulWidget {
  final BankAccount? selectedAccount;
  final Function(BankAccount?) onChanged;
  final String? label;

  const BankAccountSelector({
    Key? key,
    this.selectedAccount,
    required this.onChanged,
    this.label,
  }) : super(key: key);

  @override
  State<BankAccountSelector> createState() => _BankAccountSelectorState();
}

class _BankAccountSelectorState extends State<BankAccountSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().loadBankAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BankAccountProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return _buildLoadingState();
        if (provider.error != null) return _buildErrorState(provider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(widget.label!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            SearchableDropdown<BankAccount>(
              value: widget.selectedAccount,
              items: provider.activeBankAccounts,
              itemAsString: (account) => account.displayName,
              hint: 'เลือกบัญชีรับเงิน',
              allowClear: true,
              onChanged: (account) => widget.onChanged(account),
            ),
            if (widget.selectedAccount != null) ...[
              const SizedBox(height: 8),
              _buildSummaryBox(widget.selectedAccount!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('กำลังโหลดข้อมูลบัญชีธนาคาร...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BankAccountProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ไม่สามารถโหลดข้อมูลบัญชีธนาคารได้', style: TextStyle(color: Colors.red.shade700))),
              TextButton(onPressed: () => provider.loadBankAccounts(), child: const Text('ลองใหม่')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(BankAccount account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('บัญชีที่เลือก:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
          const SizedBox(height: 4),
          Text(account.bankName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
          Text(account.bankAccountName, style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
          Text(account.accountNumber, style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
        ],
      ),
    );
  }
}