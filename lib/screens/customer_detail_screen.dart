import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../widgets/responsive_layout.dart';
import '../utils/date_formatter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load customers if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      if (provider.allCustomers.isEmpty) {
        provider.loadCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.getCustomerById(widget.customerId);
          
          if (customer == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: ResponsivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Customer Header
                  _buildCustomerHeader(customer),
                  
                  const SizedBox(height: 24),
                  
                  // Customer Details
                  _buildCustomerDetails(customer),
                  
                  const SizedBox(height: 24),
                  
                  // Contacts Section
                  _buildContactsSection(customer),
                  
                  const SizedBox(height: 24),
                  
                  // Bank Accounts Section
                  _buildBankAccountsSection(customer),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildCustomerHeader(Customer customer) {
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
                  'รายละเอียดลูกค้า',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editCustomer(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('แก้ไข'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Customer Name
            ResponsiveText(
              customer.companyName.isNotEmpty ? customer.companyName : customer.contactName,
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

  Widget _buildCustomerDetails(Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลลูกค้า',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('รหัสลูกค้า', customer.customerCode),
            const SizedBox(height: 12),
            _buildDetailRow('ชื่อบริษัท', customer.companyName),
            const SizedBox(height: 12),
            _buildDetailRow('เลขที่ผู้เสียภาษี', customer.taxId),
            const SizedBox(height: 12),
            _buildDetailRow('ที่อยู่', customer.address),
            const SizedBox(height: 12),
            _buildDetailRow('ช่องทางติดต่อ', customer.contactMethod),
            const SizedBox(height: 12),
            _buildDetailRow('สร้างเมื่อ', _formatDate(customer.createdAt)),
            const SizedBox(height: 12),
            _buildDetailRow('อัปเดตล่าสุด', _formatDate(customer.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection(Customer customer) {
    // รวม contacts จาก array และ legacy fields
    final contacts = customer.contacts.isNotEmpty
        ? customer.contacts
        : (customer.contactName.isNotEmpty
            ? [customer.primaryContact!]
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

  Widget _buildBankAccountsSection(Customer customer) {
    final bankAccounts = customer.bankAccounts;

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
          width: 120,
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

  void _editCustomer() {
    context.push('/customer-form?id=${widget.customerId}');
  }
}
