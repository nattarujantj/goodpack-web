import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import '../widgets/responsive_layout.dart';

class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({Key? key, required this.supplierId}) : super(key: key);

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load suppliers if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SupplierProvider>();
      if (provider.allSuppliers.isEmpty) {
        provider.loadSuppliers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
        builder: (context, supplierProvider, child) {
          final supplier = supplierProvider.getSupplierById(widget.supplierId);
          
          if (supplier == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
            _buildDetailRow('ชื่อผู้ติดต่อ', supplier.contactName),
            const SizedBox(height: 12),
            _buildDetailRow('เลขที่ผู้เสียภาษี', supplier.taxId),
            const SizedBox(height: 12),
            _buildDetailRow('เบอร์โทร', supplier.phone),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editSupplier() {
    context.push('/supplier-form?id=${widget.supplierId}');
  }
}

