import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../providers/purchase_provider.dart';
import '../models/purchase.dart';
import '../widgets/responsive_layout.dart';
import '../services/config_service.dart';
import '../utils/number_formatter.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final String purchaseId;

  const PurchaseDetailScreen({Key? key, required this.purchaseId}) : super(key: key);

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load purchases if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseProvider>();
      if (provider.allPurchases.isEmpty) {
        provider.loadPurchases();
      }
    });
  }

  void _openProductDetail(String productId) {
    if (productId.isEmpty) return;
    
    if (kIsWeb) {
      // Open in new tab for web
      final baseUrl = Uri.base.origin;
      html.window.open('$baseUrl/#/product/$productId', '_blank');
    } else {
      // Navigate within app for mobile
      context.push('/product/$productId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, purchaseProvider, child) {
        final purchase = purchaseProvider.getPurchaseById(widget.purchaseId);
        
        if (purchase == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: ResponsivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Purchase Header
                _buildPurchaseHeader(purchase),
                
                const SizedBox(height: 24),
                
                // Purchase Details
                _buildPurchaseDetails(purchase),
                
                const SizedBox(height: 24),
                
                // Customer Information
                _buildCustomerInfo(purchase),
                
                const SizedBox(height: 24),
                
                // Purchase Items
                _buildPurchaseItems(purchase),
                
                const SizedBox(height: 24),
                
                // Payment Information
                _buildPaymentInfo(purchase),
                
                const SizedBox(height: 24),
                
                // Warehouse Information
                _buildWarehouseInfo(purchase),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchaseHeader(Purchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'รายละเอียดการซื้อ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editPurchase(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('แก้ไข'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Purchase ID and Date
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('รหัสการซื้อ', purchase.id),
                ),
                Expanded(
                  child: _buildDetailRow('วันที่ซื้อ', _formatDate(purchase.purchaseDate)),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Customer and VAT Status
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('ซัพพลายเออร์', purchase.supplierName),
                ),
                Expanded(
                  child: _buildDetailRow('VAT', purchase.isVAT ? 'มี' : 'ไม่มี'),
                ),
              ],
            ),
            
            // Notes (if exists)
            if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('รายละเอียด', purchase.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseDetails(Purchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'สรุปการซื้อ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('รหัสรายการซื้อ', purchase.purchaseCode),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('จำนวนรายการ', '${purchase.items.length}'),
                ),
                Expanded(
                  child: _buildDetailRow('ยอดรวม', NumberFormatter.formatPriceWithCurrency(purchase.totalAmount)),
                ),
              ],
            ),
            
            if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('รายละเอียด', purchase.notes!),
            ],
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('VAT (7%)', NumberFormatter.formatPriceWithCurrency(purchase.totalVAT)),
                ),
                Expanded(
                  child: _buildDetailRow('ยอดรวมทั้งสิ้น', NumberFormatter.formatPriceWithCurrency(purchase.grandTotal)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItems(Purchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'รายการสินค้า',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (purchase.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ResponsiveText(
                        'ไม่มีรายการสินค้า',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...purchase.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildPurchaseItemRow(index, item);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItemRow(int index, PurchaseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openProductDetail(item.productId),
                  child: Text(
                    '${index + 1}. ${item.productName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Text(
                NumberFormatter.formatPriceWithCurrency(item.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('รหัส: ${item.productCode}'),
              ),
              Expanded(
                child: Text('จำนวน: ${NumberFormatter.formatQuantity(item.quantity)}'),
              ),
              Expanded(
                child: Text('ราคา/ชิ้น: ${NumberFormatter.formatPriceWithCurrency(item.unitPrice)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Purchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลการชำระเงิน',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('สถานะการชำระ', purchase.payment.isPaid ? 'ชำระแล้ว' : 'ยังไม่ชำระ'),
            
            if (purchase.payment.paymentMethod != null)
              _buildDetailRow('วิธีการชำระ', purchase.payment.paymentMethod!),
            
            if (purchase.payment.ourAccount != null)
              _buildDetailRow('บัญชีที่ใช้จ่าย', _getAccountDisplayName(purchase.payment.ourAccount!)),
            
            if (purchase.payment.customerAccount != null)
              _buildDetailRow('บัญชีลูกค้า', purchase.payment.customerAccount!),
            
            if (purchase.payment.paymentDate != null)
              _buildDetailRow('วันที่ชำระ', _formatDate(purchase.payment.paymentDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseInfo(Purchase purchase) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลคลังสินค้า',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('สถานะการอัปเดต', purchase.warehouse.isUpdated ? 'อัปเดตแล้ว' : 'ยังไม่อัปเดต'),
            
            if (purchase.warehouse.notes != null)
              _buildDetailRow('หมายเหตุ', purchase.warehouse.notes!),
            
            if (purchase.warehouse.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              ResponsiveText(
                'รายการคลังสินค้า',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...purchase.warehouse.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildWarehouseItemRow(index, item);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseItemRow(int index, WarehouseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openProductDetail(item.productId),
              child: Text(
                '${index + 1}. ${item.productName}',
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Text('จำนวน: ${NumberFormatter.formatQuantity(item.quantity)}'),
          const SizedBox(width: 16),
          Text('ลัง: ${NumberFormatter.formatQuantity(item.boxes)}'),
          if (item.notes != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Text('หมายเหตุ: ${item.notes}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: ResponsiveText(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCustomerInfo(Purchase purchase) {
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
            
            _buildDetailRow('ชื่อบริษัท', purchase.supplierName),
            
            if (purchase.contactName != null && purchase.contactName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('ชื่อผู้ติดต่อ', purchase.contactName!),
            ],
            
            if (purchase.supplierCode != null && purchase.supplierCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('รหัสซัพพลายเออร์', purchase.supplierCode!),
            ],
            
            if (purchase.taxId != null && purchase.taxId!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('เลขที่ผู้เสียภาษี', purchase.taxId!),
            ],
            
            if (purchase.address != null && purchase.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('ที่อยู่', purchase.address!),
            ],
            
            if (purchase.phone != null && purchase.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('เบอร์โทร', purchase.phone!),
            ],
          ],
        ),
      ),
    );
  }

  String _getAccountDisplayName(String accountId) {
    // Get account details from ConfigService
    final accounts = ConfigService().accounts;
    final account = accounts.firstWhere(
      (acc) => acc.id == accountId,
      orElse: () => accounts.first, // fallback
    );
    
    return '${account.name} (${account.accountNumber}) - ${account.bankName}';
  }

  void _editPurchase() {
    context.push('/purchase-form?id=${widget.purchaseId}');
  }
}
