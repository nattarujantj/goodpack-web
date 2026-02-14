import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../models/quotation.dart';
import '../providers/quotation_provider.dart';
import '../providers/sale_provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/pdf_service_thai_enhanced.dart';
import '../models/bank_account.dart';
import '../utils/number_formatter.dart';
import '../utils/date_formatter.dart';

class QuotationDetailScreen extends StatefulWidget {
  final String quotationId;

  const QuotationDetailScreen({
    Key? key,
    required this.quotationId,
  }) : super(key: key);

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  bool _isLoading = false;
  bool _errorNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    final quotationProvider = context.read<QuotationProvider>();
    if (quotationProvider.getQuotationById(widget.quotationId) != null) return;

    setState(() => _isLoading = true);
    try {
      final quotation = await quotationProvider.fetchQuotationById(widget.quotationId);
      if (mounted && quotation == null) {
        setState(() => _errorNotFound = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return Scaffold(
      
      body: Consumer<QuotationProvider>(
        builder: (context, quotationProvider, child) {
          if (_isLoading || quotationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final quotation = quotationProvider.getQuotationById(widget.quotationId);
          if (quotation == null) {
            if (_errorNotFound) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลเสนอราคา',
                      style: TextStyle(color: Colors.red[700], fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/quotations'),
                      child: const Text('กลับไปรายการเสนอราคา'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Buttons - ย้ายมาด้านบน
              _buildActionButtons(quotation),
              const SizedBox(height: 16),
              
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ResponsiveText(
                                  'เสนอราคา #${quotation.quotationCode}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'วันที่: ${_formatDate(quotation.quotationDate)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(quotation.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  quotation.statusDisplay,
                                  style: TextStyle(
                                    color: _getStatusColor(quotation.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (quotation.saleCode != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ขายแล้ว: ${quotation.saleCode}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Customer Information Card
              Card(
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
                      _buildInfoRow('ชื่อลูกค้า', quotation.customerName),
                      if (quotation.contactName != null)
                        _buildInfoRow('ชื่อผู้ติดต่อ', quotation.contactName!),
                      if (quotation.customerCode != null)
                        _buildInfoRow('รหัสลูกค้า', quotation.customerCode!),
                      if (quotation.taxId != null)
                        _buildInfoRow('เลขประจำตัวผู้เสียภาษี', quotation.taxId!),
                      if (quotation.address != null)
                        _buildInfoRow('ที่อยู่', quotation.address!),
                      if (quotation.phone != null)
                        _buildInfoRow('เบอร์โทรศัพท์', quotation.phone!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items Card
              Card(
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
                      _buildItemsTable(quotation.items),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'สรุปยอดรวม',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummarySection(quotation),
                    ],
                  ),
                ),
              ),

              // Bank Account Information Card
              if (quotation.bankName != null || quotation.bankAccountName != null || quotation.bankAccountNumber != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          'ข้อมูลบัญชีธนาคาร',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (quotation.bankName != null)
                          _buildInfoRow('ธนาคาร', quotation.bankName!),
                        if (quotation.bankAccountName != null)
                          _buildInfoRow('ชื่อบัญชี', quotation.bankAccountName!),
                        if (quotation.bankAccountNumber != null)
                          _buildInfoRow('เลขที่บัญชี', quotation.bankAccountNumber!),
                      ],
                    ),
                  ),
                ),
              ],

              if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          'หมายเหตุ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(quotation.notes!),
                      ],
                    ),
                  ),
                ),
              ],

            ],
          ),
        );
        },
      ),
      floatingActionButton: Consumer<QuotationProvider>(
        builder: (context, quotationProvider, child) {
          final quotation = quotationProvider.getQuotationById(widget.quotationId);
          if (quotation == null) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _printQuotationPdf(quotation),
            icon: const Icon(Icons.print),
            label: const Text('พิมพ์ PDF'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Quotation quotation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/quotation-form?id=${quotation.id}'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('แก้ไข'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (quotation.saleCode == null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createSaleFromQuotation(quotation),
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('สร้างรายการขาย'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goToSale(quotation.saleCode!),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('ดูรายการขาย'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(quotation),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<QuotationItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 600, // กำหนดความกว้างขั้นต่ำที่เหมาะสม
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 12,
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(
                label: Text('สินค้า'),
                numeric: false,
              ),
              DataColumn(
                label: Text('รหัส'),
                numeric: false,
              ),
              DataColumn(
                label: Text('จำนวน'),
                numeric: true,
              ),
              DataColumn(
                label: Text('ราคาต่อหน่วย'),
                numeric: true,
              ),
              DataColumn(
                label: Text('รวม'),
                numeric: true,
              ),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80),
                      child: InkWell(
                        onTap: () => _openProductDetail(item.productId),
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80),
                      child: Text(item.productCode),
                    ),
                  ),
                  DataCell(
                    Text(
                      NumberFormatter.formatQuantity(item.quantity),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  DataCell(
                    Text(
                      NumberFormatter.formatPriceWithCurrency(item.unitPrice),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  DataCell(
                    Text(
                      NumberFormatter.formatPriceWithCurrency(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Quotation quotation) {
    final subtotal = quotation.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final vatAmount = quotation.isVAT ? subtotal * 0.07 : 0.0;
    final grandTotal = quotation.calculateGrandTotal();

    return Column(
      children: [
        _buildSummaryRow('ยอดรวมก่อน VAT', subtotal),
        if (quotation.isVAT) _buildSummaryRow('VAT (7%)', vatAmount),
        _buildSummaryRow('ค่าขนส่ง', quotation.shippingCost),
        const Divider(),
        _buildSummaryRow('ยอดรวมทั้งสิ้น', grandTotal, isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormatter.formatPriceWithCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _createSaleFromQuotation(Quotation quotation) async {
    try {
      // อัพเดตสถานะเป็น 'accepted' เมื่อสร้างรายการขาย
      await context.read<QuotationProvider>().updateQuotationStatus(quotation.id, 'accepted');
      
      // Navigate to sale form with quotation ID for pre-filling
      context.push('/sale-form?quotationId=${quotation.id}');
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

  void _goToSale(String saleCode) async {
    try {
      // Load sales to find the one with matching code
      await context.read<SaleProvider>().loadSales();
      
      // Find sale by code
      final sales = context.read<SaleProvider>().sales;
      final sale = sales.firstWhere(
        (s) => s.saleCode == saleCode,
        orElse: () => throw Exception('Sale not found'),
      );
      
      // Navigate to sale detail
      context.go('/sale/${sale.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบรายการขาย: $saleCode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printQuotationPdf(Quotation quotation) async {
    // แสดง dialog ให้ระบุชื่อผู้ลงนาม
    final signerNameController = TextEditingController(
      text: PdfServiceThaiEnhanced.defaultSignerName,
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
      // สร้าง BankAccount จากข้อมูลใน quotation
      BankAccount? bankAccount;
      if (quotation.bankAccountId != null) {
        bankAccount = BankAccount(
          id: quotation.bankAccountId!,
          bankName: quotation.bankName ?? 'ธนาคารกสิกรไทย',
          bankAccountName: quotation.bankAccountName ?? 'บริษัท กู๊ดแพ็คเกจจิ้งซัพพลาย จำกัด',
          accountNumber: quotation.bankAccountNumber ?? '106-3-40679-8',
        );
      }

      // สร้างและพิมพ์ PDF ไทย (สำหรับ Web จะเปิด tab ใหม่ทันที)
      await PdfServiceThaiEnhanced.generateAndPrintQuotation(
        quotation, 
        bankAccount: bankAccount,
        signerName: signerName,
      );

      // อัพเดตสถานะเป็น 'sent' เมื่อพิมพ์ (เฉพาะถ้ายังเป็น draft)
      if (quotation.status == 'draft') {
        await context.read<QuotationProvider>().updateQuotationStatus(quotation.id, 'sent');
      }

      // แสดง snackbar เมื่อสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปิด PDF ในแท็บใหม่แล้ว'),
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

  void _showDeleteDialog(Quotation quotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบเสนอราคา "${quotation.quotationCode}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบเสนอราคาเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.pop();
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}