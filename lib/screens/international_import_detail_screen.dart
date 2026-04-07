import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/international_import.dart';
import '../providers/international_import_provider.dart';
import '../widgets/responsive_layout.dart';
import '../utils/date_formatter.dart';
import '../utils/error_dialog.dart';

class InternationalImportDetailScreen extends StatefulWidget {
  final String importId;

  const InternationalImportDetailScreen({Key? key, required this.importId}) : super(key: key);

  @override
  State<InternationalImportDetailScreen> createState() => _InternationalImportDetailScreenState();
}

class _InternationalImportDetailScreenState extends State<InternationalImportDetailScreen> {
  InternationalImport? _import;
  bool _isLoading = true;

  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<InternationalImportProvider>();
    var imp = provider.getById(widget.importId);
    imp ??= await provider.fetchById(widget.importId);
    if (mounted) {
      setState(() {
        _import = imp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: ResponsiveAppBar(title: 'รายละเอียดการนำเข้า'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_import == null) {
      return Scaffold(
        appBar: ResponsiveAppBar(title: 'รายละเอียดการนำเข้า'),
        body: const Center(child: Text('ไม่พบรายการ')),
      );
    }

    final imp = _import!;

    return Scaffold(
      appBar: ResponsiveAppBar(
        title: imp.importCode,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'แก้ไข',
            onPressed: imp.status == 'purchased'
                ? null
                : () => context.push('/international-form?id=${imp.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'ลบ',
            onPressed: () => _confirmDelete(imp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(imp),
                const SizedBox(height: 16),
                _buildShippingCostCard(imp),
                const SizedBox(height: 16),
                _buildItemsCard(imp),
                const SizedBox(height: 16),
                _buildSummaryCard(imp),
                if (imp.notes != null && imp.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(imp),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(imp),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(InternationalImport imp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(imp.importCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                _buildStatusBadge(imp.status),
              ],
            ),
            const Divider(height: 24),
            _infoRow('วันที่นำเข้า', DateFormatter.formatDate(imp.importDate)),
            _infoRow('ประเภท', imp.importType == 'LCL' ? 'LCL (แชร์ตู้)' : 'FCL (เต็มตู้)'),
            _infoRow('Supplier', imp.supplierName),
            _infoRow('Shipping Company', imp.shippingCompanyName),
            _infoRow('อัตราแลกเปลี่ยน', '${_currencyFormat.format(imp.usdToThbRate)} THB/USD'),
            if (imp.status == 'purchased' && imp.purchaseId != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => context.push('/purchase/${imp.purchaseId}'),
                  child: Row(
                    children: [
                      const Text('รายการซื้อ: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('ดูรายการซื้อ', style: TextStyle(color: Colors.blue[700], decoration: TextDecoration.underline)),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new, size: 16, color: Colors.blue[700]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _infoRow(
                  'ประเภทรายการซื้อ',
                  imp.purchaseIsVAT == true ? 'VAT' : 'ไม่ VAT',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingCostCard(InternationalImport imp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ราคาค่าส่ง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (imp.importType == 'LCL') ...[
              _infoRow('ราคาต่อคิว', '${_currencyFormat.format(imp.pricePerCBM)} บาท/CBM'),
            ] else ...[
              ...imp.fclCostDetails.map((d) => _infoRow(d.name, '${_currencyFormat.format(d.amount)} บาท')),
              const Divider(),
              _infoRow('รวมค่าตู้', '${_currencyFormat.format(imp.totalFCLCost)} บาท', isBold: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(InternationalImport imp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รายการสินค้า (${imp.items.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('สินค้า')),
                  DataColumn(label: Text('USD/ชิ้น'), numeric: true),
                  DataColumn(label: Text('จำนวน'), numeric: true),
                  DataColumn(label: Text('ชิ้น/ลัง'), numeric: true),
                  DataColumn(label: Text('กล่อง')),
                  DataColumn(label: Text('CBM'), numeric: true),
                  DataColumn(label: Text('ค่าส่ง/ชิ้น'), numeric: true),
                  DataColumn(label: Text('Commission'), numeric: true),
                  DataColumn(label: Text('จ่าย Comm.')),
                  DataColumn(label: Text('ต้นทุน/ชิ้น\n(ก่อน VAT)'), numeric: true),
                  DataColumn(label: Text('VAT/ชิ้น'), numeric: true),
                  DataColumn(label: Text('ต้นทุน/ชิ้น\n(หลัง VAT)'), numeric: true),
                  DataColumn(label: Text('รวม'), numeric: true),
                ],
                rows: imp.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('${idx + 1}')),
                    DataCell(Text('${item.productCode}\n${item.productName}', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(_currencyFormat.format(item.usdPricePerUnit))),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text('${item.piecesPerBox}')),
                    DataCell(Text('${item.boxWidth}x${item.boxLength}x${item.boxHeight}')),
                    DataCell(Text(item.cbm.toStringAsFixed(1))),
                    DataCell(Text(_currencyFormat.format(item.shippingCostPerUnit))),
                    DataCell(Text(_currencyFormat.format(item.commission))),
                    DataCell(Icon(
                      item.commissionPaid ? Icons.check_circle : Icons.cancel,
                      color: item.commissionPaid ? Colors.green : Colors.red[300],
                      size: 20,
                    )),
                    DataCell(Text(_currencyFormat.format(item.costPerUnitBeforeVAT))),
                    DataCell(Text(_currencyFormat.format(item.vatPerUnit))),
                    DataCell(Text(_currencyFormat.format(item.costPerUnitAfterVAT))),
                    DataCell(Text(_currencyFormat.format(item.totalCost))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(InternationalImport imp) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('สรุป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('รวม CBM', '${imp.totalCBM.toStringAsFixed(1)} คิว'),
            _infoRow('รวมต้นทุนสินค้า', '${_currencyFormat.format(imp.totalProductCost)} บาท'),
            _infoRow('รวมค่าส่ง', '${_currencyFormat.format(imp.totalShippingCost)} บาท'),
            const Divider(),
            _infoRow('รวมทั้งหมด', '${_currencyFormat.format(imp.grandTotal)} บาท', isBold: true, fontSize: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(InternationalImport imp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('หมายเหตุ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(imp.notes ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(InternationalImport imp) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไข'),
            onPressed: imp.status == 'purchased'
                ? null
                : () => context.push('/international-form?id=${imp.id}'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('สร้างรายการซื้อ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: imp.status == 'purchased' ? null : () => _createPurchase(imp),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPurchased = status == 'purchased';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPurchased ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPurchased ? 'สร้างรายการซื้อแล้ว' : 'Draft',
        style: TextStyle(
          color: isPurchased ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: fontSize)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: fontSize)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(InternationalImport imp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบรายการนำเข้า ${imp.importCode} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<InternationalImportProvider>().delete(imp.id);
              if (success && mounted) {
                context.go('/internationals');
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _createPurchase(InternationalImport imp) {
    bool isVAT = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('สร้างรายการซื้อ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ระบบจะสร้างรายการซื้อจากรายการนำเข้านี้'),
              const SizedBox(height: 16),
              const Text('ประเภทรายการซื้อ', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('VAT')),
                  ButtonSegment(value: false, label: Text('ไม่ VAT')),
                ],
                selected: {isVAT},
                onSelectionChanged: (v) => setDialogState(() => isVAT = v.first),
              ),
              const SizedBox(height: 12),
              Text(
                isVAT ? 'ราคาต่อชิ้นจะใช้ราคาหลัง VAT' : 'ราคาต่อชิ้นจะใช้ราคาก่อน VAT',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final provider = context.read<InternationalImportProvider>();
                final result = await provider.createPurchaseFromImport(imp.id, isVAT: isVAT);
                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('สร้างรายการซื้อเรียบร้อย (${isVAT ? "VAT" : "ไม่ VAT"})'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadData();
                } else if (mounted) {
                  ErrorDialog.showServerError(context, provider.error);
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('สร้างรายการซื้อ'),
            ),
          ],
        ),
      ),
    );
  }
}
