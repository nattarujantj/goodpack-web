import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../widgets/responsive_layout.dart';

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
            _buildDetailRow('ชื่อผู้ติดต่อ', customer.contactName),
            const SizedBox(height: 12),
            _buildDetailRow('เลขที่ผู้เสียภาษี', customer.taxId),
            const SizedBox(height: 12),
            _buildDetailRow('เบอร์โทร', customer.phone),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editCustomer() {
    context.go('/customer-form?id=${widget.customerId}');
  }
}
