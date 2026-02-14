import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import '../widgets/responsive_layout.dart';
import '../utils/date_formatter.dart';

class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({Key? key, required this.supplierId}) : super(key: key);

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplier());
  }

  Future<void> _loadSupplier() async {
    final provider = context.read<SupplierProvider>();
    if (provider.getSupplierById(widget.supplierId) != null) return;
    final supplier = await provider.fetchSupplierById(widget.supplierId);
    if (mounted && supplier == null) {
      setState(() => _error = 'ไม่พบข้อมูลซัพพลายเออร์');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
        builder: (context, supplierProvider, child) {
          final supplier = supplierProvider.getSupplierById(widget.supplierId);

          if (supplier == null) {
            if (_error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 18)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/suppliers'),
                      child: const Text('กลับไปรายการซัพพลายเออร์'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: ResponsivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Supplier Header
                  _buildSupplierHeader(supplier),
                  
                  const SizedBox(height: 24),
                  
                  // Supplier Details
                  _buildSupplierDetails(supplier),
                  
                  const SizedBox(height: 24),
                  
                  // Contacts Section
                  _buildContactsSection(supplier),
                  
                  const SizedBox(height: 24),
                  
                  // Bank Accounts Section
                  _buildBankAccountsSection(supplier),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildSupplierHeader(Supplier supplier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'รายละเอียดซัพพลายเออร์',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editSupplier(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('แก้ไข'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Supplier Name
            ResponsiveText(
              supplier.companyName.isNotEmpty ? supplier.companyName : supplier.contactName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDetails(Supplier supplier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลซัพพลายเออร์',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('รหัสซัพพลายเออร์', supplier.supplierCode),
            const SizedBox(height: 12),
            _buildDetailRow('ชื่อบริษัท', supplier.companyName),
            const SizedBox(height: 12),
            _buildDetailRow('เลขที่ผู้เสียภาษี', supplier.taxId),
            const SizedBox(height: 12),
            _buildDetailRow('ที่อยู่', supplier.address),
            const SizedBox(height: 12),
            _buildDetailRow('ช่องทางติดต่อ', supplier.contactMethod),
            const SizedBox(height: 12),
            _buildDetailRow('สร้างเมื่อ', _formatDate(supplier.createdAt)),
            const SizedBox(height: 12),
            _buildDetailRow('อัปเดตล่าสุด', _formatDate(supplier.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection(Supplier supplier) {
    // รวม contacts จาก array และ legacy fields
    final contacts = supplier.contacts.isNotEmpty
        ? supplier.contacts
        : (supplier.contactName.isNotEmpty
            ? [supplier.primaryContact!]
            : []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                ResponsiveText(
                  'ผู้ติดต่อ (${contacts.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (contacts.isEmpty)
              Text(
                'ไม่มีข้อมูลผู้ติดต่อ',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...contacts.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: contact.isDefault ? Colors.blue : Colors.grey.shade300,
                      width: contact.isDefault ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: contact.isDefault ? Colors.blue.shade50 : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (contact.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'หลัก',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (contact.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    contact.phone,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountsSection(Supplier supplier) {
    final bankAccounts = supplier.bankAccounts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.green),
                const SizedBox(width: 8),
                ResponsiveText(
                  'บัญชีธนาคาร (${bankAccounts.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (bankAccounts.isEmpty)
              Text(
                'ไม่มีข้อมูลบัญชีธนาคาร',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...bankAccounts.map((account) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: account.isDefault ? Colors.green : Colors.grey.shade300,
                      width: account.isDefault ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: account.isDefault ? Colors.green.shade50 : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  account.bankName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (account.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'หลัก',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account.accountName,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.accountNumber,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: ResponsiveText(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ResponsiveText(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDateTime(date);
  }

  void _editSupplier() {
    context.push('/supplier-form?id=${widget.supplierId}');
  }
}
