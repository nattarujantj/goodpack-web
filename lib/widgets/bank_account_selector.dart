import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';

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
    // โหลดข้อมูลบัญชีธนาคารเมื่อ widget ถูกสร้าง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankAccountProvider>().loadBankAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BankAccountProvider>(
      builder: (context, bankAccountProvider, child) {
        final bankAccounts = bankAccountProvider.activeBankAccounts;

        // แสดง loading indicator ถ้ากำลังโหลดข้อมูล
        if (bankAccountProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    SizedBox(width: 12),
                    Text('กำลังโหลดข้อมูลบัญชีธนาคาร...'),
                  ],
                ),
              ),
            ],
          );
        }

        // แสดง error ถ้ามี
        if (bankAccountProvider.error != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไม่สามารถโหลดข้อมูลบัญชีธนาคารได้',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => bankAccountProvider.loadBankAccounts(),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BankAccount?>(
                  value: widget.selectedAccount,
                  hint: const Text('เลือกบัญชีรับเงิน'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<BankAccount?>(
                      value: null,
                      child: Text('ไม่ระบุบัญชี'),
                    ),
                    ...bankAccounts.map((account) {
                      return DropdownMenuItem<BankAccount?>(
                        value: account,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              account.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              account.bankAccountName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            if (widget.selectedAccount != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บัญชีที่เลือก:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.selectedAccount!.bankName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      widget.selectedAccount!.bankAccountName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    Text(
                      widget.selectedAccount!.accountNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
