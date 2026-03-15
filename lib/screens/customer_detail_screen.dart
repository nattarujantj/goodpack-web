import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../services/sale_api_service.dart';
import '../widgets/responsive_layout.dart';
import '../utils/date_formatter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  String? _error;

  List<Sale> _customerSales = [];
  bool _salesLoading = false;
  String? _salesError;

  final SaleApiService _saleApiService = SaleApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomer();
      _loadCustomerSales();
    });
  }

  Future<void> _loadCustomer() async {
    final provider = context.read<CustomerProvider>();
    if (provider.getCustomerById(widget.customerId) != null) return;
    final customer = await provider.fetchCustomerById(widget.customerId);
    if (mounted && customer == null) {
      setState(() => _error = 'ไม่พบข้อมูลลูกค้า');
    }
  }

  Future<void> _loadCustomerSales() async {
    if (!mounted) return;
    setState(() {
      _salesLoading = true;
      _salesError = null;
    });
    try {
      final sales = await _saleApiService.getSalesByCustomer(widget.customerId);
      if (mounted) {
        setState(() {
          _customerSales = sales;
          _salesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _salesError = e.toString();
          _salesLoading = false;
        });
      }
    }
  }

  /// Aggregate sales into monthly summary per product
  /// Returns list of maps: {monthKey, monthLabel, productName, qty, net, vat, total}
  List<Map<String, dynamic>> _buildMonthlySummaryData() {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final sale in _customerSales) {
      final thaiDate = DateFormatter.toThailand(sale.saleDate);
      final monthKey = '${thaiDate.year.toString().padLeft(4, '0')}-${thaiDate.month.toString().padLeft(2, '0')}';
      final monthLabel = '${thaiDate.month.toString().padLeft(2, '0')}/${thaiDate.year}';

      for (final item in sale.items) {
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
        if (!sale.isVAT) {
          net = item.totalPrice;
          vat = 0.0;
          total = item.totalPrice;
        } else if (sale.vatType == 'exclusive') {
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
    return Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.getCustomerById(widget.customerId);

          if (customer == null) {
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
                      onPressed: () => context.go('/customers'),
                      child: const Text('กลับไปรายการลูกค้า'),
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

                  const SizedBox(height: 24),

                  // Monthly Sales Summary
                  _buildMonthlySalesSummary(),

                  const SizedBox(height: 24),

                  // Recent Sales Transactions
                  _buildRecentSalesTransactions(),
                  
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

  Widget _buildMonthlySalesSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'สรุปยอดขายรายเดือน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_salesLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_salesError != null)
              Text('เกิดข้อผิดพลาด: $_salesError', style: const TextStyle(color: Colors.red))
            else if (_customerSales.isEmpty)
              Text('ไม่มีข้อมูลการขาย', style: TextStyle(color: Colors.grey.shade600))
            else
              _buildMonthlySummaryTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryTable() {
    final rows = _buildMonthlySummaryData();
    final fmt = (double v) => v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    // Group rows by monthKey to inject subtotal rows
    final Map<String, List<Map<String, dynamic>>> byMonth = {};
    for (final row in rows) {
      final mk = row['monthKey'] as String;
      byMonth.putIfAbsent(mk, () => []).add(row);
    }

    final List<DataRow> dataRows = [];
    for (final monthKey in byMonth.keys) {
      final monthRows = byMonth[monthKey]!;
      bool isFirstInMonth = true;
      double monthTotalVat = 0;
      double monthGrandTotal = 0;

      for (final row in monthRows) {
        monthTotalVat += row['vat'] as double;
        monthGrandTotal += row['total'] as double;

        dataRows.add(DataRow(
          color: WidgetStateProperty.resolveWith((states) {
            return isFirstInMonth ? Colors.indigo.shade50.withOpacity(0.5) : null;
          }),
          cells: [
            DataCell(Text(isFirstInMonth ? row['monthLabel'] as String : '',
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
        ));
        isFirstInMonth = false;
      }

      // Subtotal row for this month
      dataRows.add(DataRow(
        color: WidgetStateProperty.all(Colors.indigo.shade100),
        cells: [
          const DataCell(Text('')),
          const DataCell(Text('รวมเดือน',
              style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
          const DataCell(Text('')),
          const DataCell(Text('')),
          DataCell(Text(fmt(monthTotalVat),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
          DataCell(Text(fmt(monthGrandTotal),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
        ],
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
        columns: const [
          DataColumn(label: Text('เดือน', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('สินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('จำนวน', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('ราคาก่อน VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('VAT (7%)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('รวมทั้งสิ้น', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: dataRows,
      ),
    );
  }

  Widget _buildRecentSalesTransactions() {
    final recent = _customerSales.take(10).toList();
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
                const Icon(Icons.receipt_long, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'รายการขายล่าสุด 10 รายการ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_salesLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_salesError != null)
              Text('เกิดข้อผิดพลาด: $_salesError', style: const TextStyle(color: Colors.red))
            else if (recent.isEmpty)
              Text('ไม่มีข้อมูลการขาย', style: TextStyle(color: Colors.grey.shade600))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                  columns: const [
                    DataColumn(label: Text('เลขที่บิล', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('รายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ยอดรวม', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('สถานะชำระ', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: recent.map((sale) {
                    double totalNet = 0, totalVat = 0, grandTotal = 0;
                    for (final item in sale.items) {
                      if (!sale.isVAT) {
                        totalNet += item.totalPrice;
                      } else if (sale.vatType == 'exclusive') {
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
                    if (!sale.isVAT) grandTotal = totalNet;
                    grandTotal += sale.shippingCost;

                    final itemSummary = sale.items.length == 1
                        ? sale.items.first.productName
                        : '${sale.items.first.productName} +${sale.items.length - 1} รายการ';

                    return DataRow(cells: [
                      DataCell(
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context.go('/sale/${sale.id}'),
                          child: Text(
                            sale.saleCode,
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormatter.formatDate(sale.saleDate))),
                      DataCell(Text(itemSummary, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(fmt(grandTotal), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(fmt(totalVat))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sale.payment.isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sale.payment.isPaid ? 'ชำระแล้ว' : 'ค้างชำระ',
                            style: TextStyle(
                              fontSize: 12,
                              color: sale.payment.isPaid ? Colors.green.shade700 : Colors.orange.shade700,
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
