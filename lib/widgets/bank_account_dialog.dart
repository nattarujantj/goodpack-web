import 'package:flutter/material.dart';
import '../models/bank_account.dart';

class BankAccountDialog extends StatefulWidget {
  final BankAccount? selectedAccount;
  final Function(BankAccount?) onConfirm;

  const BankAccountDialog({
    Key? key,
    this.selectedAccount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<BankAccountDialog> {
  BankAccount? _selectedAccount;
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.selectedAccount;
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await BankAccountService.getBankAccounts();
      setState(() {
        _bankAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _bankAccounts = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลือกบัญชีรับเงิน'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'กรุณาเลือกบัญชีธนาคารสำหรับรับชำระเงิน',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // Loading indicator
          if (_isLoading) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            const Text(
              'กำลังโหลดข้อมูลบัญชีธนาคาร...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            // รายการบัญชีธนาคาร
            ..._bankAccounts.map((account) {
              final isSelected = _selectedAccount?.id == account.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAccount = account;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                    ),
                    child: Row(
                      children: [
                        // Radio button
                        Radio<BankAccount>(
                          value: account,
                          groupValue: _selectedAccount,
                          onChanged: (value) {
                            setState(() {
                              _selectedAccount = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                        
                        // ข้อมูลบัญชี
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.bankName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.blue.shade700 : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account.bankAccountName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                account.accountNumber,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Icon
                        Icon(
                          Icons.account_balance,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            // ตัวเลือกไม่ระบุบัญชี
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAccount = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAccount == null ? Colors.orange : Colors.grey.shade300,
                      width: _selectedAccount == null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selectedAccount == null ? Colors.orange.shade50 : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Radio<BankAccount?>(
                        value: null,
                        groupValue: _selectedAccount,
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ไม่ระบุบัญชี',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'ใช้ข้อมูลบัญชีเริ่มต้น',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.help_outline,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedAccount);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}

// Helper function to show the dialog
Future<BankAccount?> showBankAccountDialog(
  BuildContext context, {
  BankAccount? selectedAccount,
}) async {
  BankAccount? result;
  
  await showDialog(
    context: context,
    builder: (context) => BankAccountDialog(
      selectedAccount: selectedAccount,
      onConfirm: (account) {
        result = account;
      },
    ),
  );
  
  return result;
}
