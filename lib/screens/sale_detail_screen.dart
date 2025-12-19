import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/bank_account.dart';
import '../providers/sale_provider.dart';
import '../providers/quotation_provider.dart';
import '../services/config_service.dart';
import '../services/pdf_service_sale.dart';
import '../services/customer_service.dart';
import '../services/bank_account_service.dart' as bank_service;
import '../widgets/responsive_layout.dart';
import '../utils/number_formatter.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({Key? key, required this.saleId}) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Sale? _sale;
  bool _isLoading = true;
  String? _error;
  Customer? _customer;
  BankAccount? _ourAccount;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    try {
      final sale = context.read<SaleProvider>().getSaleById(widget.saleId);
      if (sale != null) {
        // Load additional data for display
        await _loadAdditionalData(sale);
        
        setState(() {
          _sale = sale;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'ไม่พบรายการขาย';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdditionalData(Sale sale) async {
    try {
      // Load customer data if customerId exists
      if (sale.customerId != null && sale.customerId!.isNotEmpty) {
        final customer = await CustomerService.getCustomerById(sale.customerId!);
        if (mounted) {
          setState(() {
            _customer = customer;
          });
        }
      }
      
      // Load ourAccount data if bankAccountId exists
      if (sale.bankAccountId != null && sale.bankAccountId!.isNotEmpty) {
        final ourAccount = await bank_service.BankAccountService.getBankAccountById(sale.bankAccountId!);
        if (mounted) {
          setState(() {
            _ourAccount = ourAccount;
          });
        }
      }
    } catch (e) {
      print('Error loading additional data: $e');
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            ResponsiveText(
              'เกิดข้อผิดพลาด: $_error',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/sales'),
              child: const Text('กลับไปรายการขาย'),
            ),
          ],
        ),
      );
    }

    if (_sale == null) {
      return const Center(
        child: Text('ไม่พบรายการขาย'),
      );
    }

    return Scaffold(
      body: ResponsivePadding(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildSaleDetails(),
              const SizedBox(height: 24),
              _buildCustomerInfo(_sale!),
              const SizedBox(height: 24),
              _buildSaleItems(_sale!),
              const SizedBox(height: 24),
              _buildPaymentInfo(_sale!),
              const SizedBox(height: 24),
              _buildWarehouseInfo(_sale!),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPrintPdfDialog(),
        icon: const Icon(Icons.print),
        label: const Text('พิมพ์ PDF'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/sale-form?id=${_sale!.id}'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('แก้ไข'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (_sale!.quotationCode != null && _sale!.quotationCode!.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goToQuotation(_sale!.quotationCode!),
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text('ดูเสนอราคา'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (_sale!.quotationCode != null && _sale!.quotationCode!.isNotEmpty)
              const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text('ลบ', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'รายละเอียดการขาย',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('รหัสรายการขาย', _sale!.saleCode),
            if (_sale!.quotationCode != null)
              _buildDetailRow('รหัส Quotation', _sale!.quotationCode!),
            _buildDetailRow('วันที่ขาย', _formatDate(_sale!.saleDate)),
            _buildDetailRow('ลูกค้า', _customer?.companyName ?? _sale!.customerName ?? 'ไม่ระบุ'),
            if (_sale!.contactName != null)
              _buildDetailRow('ชื่อผู้ติดต่อ', _sale!.contactName!),
            _buildDetailRow('VAT', _sale!.isVAT ? 'VAT (7%)' : 'Non-VAT'),
            _buildDetailRow('ค่าส่ง', NumberFormatter.formatPriceWithCurrency(_sale!.shippingCost)),
            if (_sale!.notes != null)
              _buildDetailRow('รายละเอียด', _sale!.notes!),
            _buildDetailRow('วันที่สร้าง', _formatDate(_sale!.createdAt)),
            _buildDetailRow('วันที่อัปเดต', _formatDate(_sale!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Sale sale) {
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
            _buildDetailRow('ชื่อบริษัท', _customer?.companyName ?? sale.customerName ?? 'ไม่ระบุ'),
            if (_customer?.contactName != null || sale.contactName != null)
              _buildDetailRow('ชื่อผู้ติดต่อ', _customer?.contactName ?? sale.contactName!),
            if (_customer?.customerCode != null || sale.customerCode != null)
              _buildDetailRow('รหัสลูกค้า', _customer?.customerCode ?? sale.customerCode!),
            if (_customer?.taxId != null || sale.taxId != null)
              _buildDetailRow('เลขที่ผู้เสียภาษี', _customer?.taxId ?? sale.taxId!),
            if (_customer?.address != null || sale.address != null)
              _buildDetailRow('ที่อยู่', _customer?.address ?? sale.address!),
            if (_customer?.phone != null || sale.phone != null)
              _buildDetailRow('เบอร์โทร', _customer?.phone ?? sale.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItems(Sale sale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'สินค้าที่ขาย',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (sale.items.isEmpty)
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
                    ResponsiveText(
                      'ไม่มีสินค้าในรายการ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...sale.items.map((item) => _buildSaleItemRow(item, sale.isVAT)),
            const SizedBox(height: 16),
            _buildTotalSummary(sale),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemRow(SaleItem item, bool isVAT) {
    final vatAmount = isVAT ? item.totalPrice * 0.07 : 0.0;
    final itemTotalWithVAT = item.totalPrice + vatAmount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openProductDetail(item.productId),
            child: Text(
              '${item.productName} (${item.productCode})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('จำนวน: ${NumberFormatter.formatQuantity(item.quantity)}'),
              ),
              Expanded(
                child: Text('ราคาต่อชิ้น: ${NumberFormatter.formatPriceWithCurrency(item.unitPrice)}'),
              ),
              Expanded(
                child: Text(
                  'รวม: ${NumberFormatter.formatPriceWithCurrency(item.totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (isVAT) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VAT (7%): ${NumberFormatter.formatPriceWithCurrency(vatAmount)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'รวม VAT: ${NumberFormatter.formatPriceWithCurrency(itemTotalWithVAT)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSummary(Sale sale) {
    final totalBeforeVAT = sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalVAT = sale.isVAT ? totalBeforeVAT * 0.07 : 0.0;
    final grandTotal = totalBeforeVAT + totalVAT + sale.shippingCost;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'สรุปยอดรวม',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ยอดรวมก่อน VAT:'),
              Text(
                NumberFormatter.formatPriceWithCurrency(totalBeforeVAT),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (sale.isVAT) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VAT (7%):'),
                Text(
                  NumberFormatter.formatPriceWithCurrency(totalVAT),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ค่าส่ง:'),
              Text(
                NumberFormatter.formatPriceWithCurrency(sale.shippingCost),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมที่ต้องรับ:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormatter.formatPriceWithCurrency(grandTotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Sale sale) {
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
            _buildDetailRow('สถานะการชำระ', sale.payment.isPaid ? 'รับเงินแล้ว' : 'ยังไม่รับเงิน'),
            if (sale.payment.paymentMethod != null)
              _buildDetailRow('วิธีการชำระเงิน', sale.payment.paymentMethod!),
            if (sale.payment.ourAccount != null)
              _buildDetailRow('บัญชีที่ใช้รับเงิน', _getAccountDisplayName(sale.payment.ourAccount!)),
            if (sale.payment.customerAccount != null)
              _buildDetailRow('บัญชีลูกค้า', sale.payment.customerAccount!),
            if (sale.payment.paymentDate != null)
              _buildDetailRow('วันที่รับเงิน', _formatDate(sale.payment.paymentDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseInfo(Sale sale) {
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
            _buildDetailRow('สถานะคลัง', sale.warehouse.isUpdated ? 'อัปเดตแล้ว' : 'ยังไม่อัปเดต'),
            if (sale.warehouse.notes != null)
              _buildDetailRow('หมายเหตุคลัง', sale.warehouse.notes!),
            if (sale.warehouse.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              ResponsiveText(
                'รายการสินค้าคลัง',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...sale.warehouse.items.map((item) => _buildWarehouseItemRow(item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseItemRow(WarehouseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openProductDetail(item.productId),
            child: Text(
              item.productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('จำนวน: ${NumberFormatter.formatQuantity(item.quantity)}')),
              Expanded(child: Text('ลัง: ${NumberFormatter.formatQuantity(item.boxes)}')),
            ],
          ),
          if (item.notes != null) ...[
            const SizedBox(height: 4),
            Text('หมายเหตุ: ${item.notes}'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountDisplayName(String accountId) {
    // Use ourAccountInfo from payment if available
    if (_sale?.payment.ourAccountInfo != null) {
      final account = _sale!.payment.ourAccountInfo!;
      return '${account.bankAccountName} (${account.accountNumber}) - ${account.bankName}';
    }
    
    // Use loaded ourAccount data if available
    if (_ourAccount != null) {
      return '${_ourAccount!.bankAccountName} (${_ourAccount!.accountNumber}) - ${_ourAccount!.bankName}';
    }
    
    // Fallback to config service
    final accounts = ConfigService().accounts;
    final account = accounts.firstWhere(
      (acc) => acc.id == accountId,
      orElse: () => accounts.first,
    );
    return '${account.name} (${account.accountNumber}) - ${account.bankName}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบรายการขาย ${_sale!.saleCode} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<SaleProvider>().deleteSale(_sale!.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบรายการขายเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/sales');
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: ${context.read<SaleProvider>().error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToQuotation(String quotationCode) async {
    try {
      // Load quotations to find the one with matching code
      await context.read<QuotationProvider>().loadQuotations();
      
      // Find quotation by code
      final quotations = context.read<QuotationProvider>().quotations;
      final quotation = quotations.firstWhere(
        (q) => q.quotationCode == quotationCode,
        orElse: () => throw Exception('Quotation not found'),
      );
      
      // Navigate to quotation detail
      context.go('/quotation/${quotation.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบเสนอราคา: $quotationCode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrintPdfDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกหัวกระดาษ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDocumentTypeOption(
              context,
              SaleDocumentType.taxInvoice,
              'ใบกำกับภาษี',
              'Tax Invoice',
              Icons.receipt_long,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildDocumentTypeOption(
              context,
              SaleDocumentType.receipt,
              'ใบเสร็จรับเงิน',
              'Receipt',
              Icons.payment,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildDocumentTypeOption(
              context,
              SaleDocumentType.taxInvoiceReceipt,
              'ใบกำกับภาษี/ใบเสร็จรับเงิน',
              'Tax Invoice/Receipt',
              Icons.description,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildDocumentTypeOption(
              context,
              SaleDocumentType.quotation,
              'ใบเสนอราคา',
              'Quotation',
              Icons.request_quote,
              Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeOption(
    BuildContext context,
    SaleDocumentType documentType,
    String thaiTitle,
    String englishTitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _printSalePdf(documentType);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thaiTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    englishTitle,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _printSalePdf(SaleDocumentType documentType) async {
    // แสดง dialog ให้ระบุชื่อผู้ลงนาม
    final signerNameController = TextEditingController(
      text: PdfServiceSale.defaultSignerName,
    );
    
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text('ระบุชื่อผู้ลงนาม'),
        content: TextField(
          controller: signerNameController,
          decoration: const InputDecoration(
            labelText: 'ชื่อผู้ลงนาม',
            hintText: 'กรอกชื่อผู้ลงนาม',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('พิมพ์ PDF'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final signerName = signerNameController.text.trim();
    if (signerName.isEmpty) return;
    
    try {
      // ใช้ข้อมูล BankAccount ที่โหลดมา หรือสร้างจากข้อมูลใน sale
      BankAccount? bankAccount = _ourAccount;
      if (bankAccount == null && _sale!.bankAccountId != null) {
        bankAccount = BankAccount(
          id: _sale!.bankAccountId!,
          bankName: _sale!.bankName ?? 'ธนาคารกสิกรไทย',
          bankAccountName: _sale!.bankAccountName ?? 'บริษัท กู๊ดแพ็คเกจจิ้งซัพพลาย จำกัด',
          accountNumber: _sale!.bankAccountNumber ?? '106-3-40679-8',
        );
      }

      // สร้างและพิมพ์ PDF (สำหรับ Web จะเปิด tab ใหม่ทันที)
      await PdfServiceSale.generateAndPrintSale(
        _sale!,
        documentType,
        bankAccount: bankAccount,
        signerName: signerName,
      );

      // แสดง snackbar เมื่อสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปิด PDF ${documentType.thaiTitle} ในแท็บใหม่แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
