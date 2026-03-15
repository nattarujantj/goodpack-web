import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../services/purchase_api_service.dart';
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

  List<Purchase> _supplierPurchases = [];
  bool _purchasesLoading = false;
  String? _purchasesError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSupplier();
      _loadSupplierPurchases();
    });
  }

  Future<void> _loadSupplier() async {
    final provider = context.read<SupplierProvider>();
    if (provider.getSupplierById(widget.supplierId) != null) return;
    final supplier = await provider.fetchSupplierById(widget.supplierId);
    if (mounted && supplier == null) {
      setState(() => _error = 'ไม่พบข้อมูลซัพพลายเออร์');
    }
  }

  Future<void> _loadSupplierPurchases() async {
    if (!mounted) return;
    setState(() {
      _purchasesLoading = true;
      _purchasesError = null;
    });
    try {
      final purchases = await PurchaseApiService.getPurchasesBySupplier(widget.supplierId);
      if (mounted) {
        setState(() {
          _supplierPurchases = purchases;
          _purchasesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasesError = e.toString();
          _purchasesLoading = false;
        });
      }
    }
  }

  /// Aggregate purchases into monthly summary per product
  List<Map<String, dynamic>> _buildMonthlyPurchaseSummaryData() {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final purchase in _supplierPurchases) {
      final thaiDate = DateFormatter.toThailand(purchase.purchaseDate);
      final monthKey = '${thaiDate.year.toString().padLeft(4, '0')}-${thaiDate.month.toString().padLeft(2, '0')}';
      final monthLabel = '${thaiDate.month.toString().padLeft(2, '0')}/${thaiDate.year}';

      for (final item in purchase.items) {
        final key = '$monthKey||${item.productId}';
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'monthKey': monthKey,
            'monthLabel': monthLabel,
            'productName': item.productName,
            'productCode': item.productCode,
            'qty': 0,
            'net': 0.0,
            'vat': 0.0,
            'total': 0.0,
          };
        }

        double net, vat, total;
        if (!purchase.isVAT) {
          net = item.totalPrice;
          vat = 0.0;
          total = item.totalPrice;
        } else if (purchase.vatType == 'exclusive') {
          net = item.totalPrice;
          vat = item.totalPrice * 0.07;
          total = item.totalPrice * 1.07;
        } else {
          // inclusive
          total = item.totalPrice;
          net = item.totalPrice / 1.07;
          vat = item.totalPrice - net;
        }

        grouped[key]!['qty'] = (grouped[key]!['qty'] as int) + item.quantity;
        grouped[key]!['net'] = (grouped[key]!['net'] as double) + net;
        grouped[key]!['vat'] = (grouped[key]!['vat'] as double) + vat;
        grouped[key]!['total'] = (grouped[key]!['total'] as double) + total;
      }
    }

    final result = grouped.values.toList();
    result.sort((a, b) => (b['monthKey'] as String).compareTo(a['monthKey'] as String));
    return result;
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

                  const SizedBox(height: 24),

                  // Monthly Purchases Summary
                  _buildMonthlyPurchasesSummary(),

                  const SizedBox(height: 24),

                  // Recent Purchases Transactions
                  _buildRecentPurchasesTransactions(),
                  
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

  Widget _buildMonthlyPurchasesSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'สรุปยอดซื้อรายเดือน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_purchasesLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_purchasesError != null)
              Text('เกิดข้อผิดพลาด: $_purchasesError', style: const TextStyle(color: Colors.red))
            else if (_supplierPurchases.isEmpty)
              Text('ไม่มีข้อมูลการซื้อ', style: TextStyle(color: Colors.grey.shade600))
            else
              _buildMonthlyPurchaseSummaryTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPurchaseSummaryTable() {
    final rows = _buildMonthlyPurchaseSummaryData();
    final fmt = (double v) => v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    String? lastMonthKey;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
        columns: const [
          DataColumn(label: Text('เดือน', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('สินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('จำนวน', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('ราคาก่อน VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('VAT (7%)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('รวมทั้งสิ้น', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: rows.map((row) {
          final isNewMonth = row['monthKey'] != lastMonthKey;
          lastMonthKey = row['monthKey'] as String;
          return DataRow(
            color: WidgetStateProperty.resolveWith((states) {
              return isNewMonth ? Colors.deepPurple.shade50.withOpacity(0.5) : null;
            }),
            cells: [
              DataCell(Text(isNewMonth ? row['monthLabel'] as String : '',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(row['productName'] as String),
                  if ((row['productCode'] as String).isNotEmpty)
                    Text(row['productCode'] as String,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              )),
              DataCell(Text('${row['qty']}')),
              DataCell(Text(fmt(row['net'] as double))),
              DataCell(Text(fmt(row['vat'] as double))),
              DataCell(Text(fmt(row['total'] as double),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentPurchasesTransactions() {
    final recent = _supplierPurchases.take(10).toList();
    final fmt = (double v) => v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.deepOrange),
                const SizedBox(width: 8),
                const Text(
                  'รายการซื้อล่าสุด 10 รายการ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_purchasesLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_purchasesError != null)
              Text('เกิดข้อผิดพลาด: $_purchasesError', style: const TextStyle(color: Colors.red))
            else if (recent.isEmpty)
              Text('ไม่มีข้อมูลการซื้อ', style: TextStyle(color: Colors.grey.shade600))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(Colors.deepOrange.shade50),
                  columns: const [
                    DataColumn(label: Text('เลขที่บิล', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('รายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ยอดรวม', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('สถานะชำระ', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: recent.map((purchase) {
                    double totalNet = 0, totalVat = 0, grandTotal = 0;
                    for (final item in purchase.items) {
                      if (!purchase.isVAT) {
                        totalNet += item.totalPrice;
                      } else if (purchase.vatType == 'exclusive') {
                        totalNet += item.totalPrice;
                        totalVat += item.totalPrice * 0.07;
                        grandTotal += item.totalPrice * 1.07;
                      } else {
                        grandTotal += item.totalPrice;
                        final net = item.totalPrice / 1.07;
                        totalNet += net;
                        totalVat += item.totalPrice - net;
                      }
                    }
                    if (!purchase.isVAT) grandTotal = totalNet;
                    grandTotal += purchase.shippingCost;

                    final itemSummary = purchase.items.length == 1
                        ? purchase.items.first.productName
                        : '${purchase.items.first.productName} +${purchase.items.length - 1} รายการ';

                    return DataRow(cells: [
                      DataCell(
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context.go('/purchase/${purchase.id}'),
                          child: Text(
                            purchase.purchaseCode,
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormatter.formatDate(purchase.purchaseDate))),
                      DataCell(Text(itemSummary, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(fmt(grandTotal), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(fmt(totalVat))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: purchase.payment.isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            purchase.payment.isPaid ? 'ชำระแล้ว' : 'ค้างชำระ',
                            style: TextStyle(
                              fontSize: 12,
                              color: purchase.payment.isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
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
