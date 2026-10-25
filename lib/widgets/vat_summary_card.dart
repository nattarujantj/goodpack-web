import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/fcl_shipment.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../utils/date_formatter.dart';
import '../utils/tax_amounts.dart';

/// หนึ่งรายการที่มี VAT (ภาษีขายหรือภาษีซื้อ) สำหรับสรุป VAT รายเดือน
class _VatEntry {
  final DateTime date;
  final String kind; // ขาย | ซื้อ | นำเข้า | ค่าตู้ | ค่าใช้จ่าย
  final String code;
  final String partner;
  final double vat;
  final bool isSale;

  _VatEntry({
    required this.date,
    required this.kind,
    required this.code,
    required this.partner,
    required this.vat,
    required this.isSale,
  });
}

/// สรุป VAT ย้อนหลังทีละเดือนของปีที่เลือก (ม.ค. ถึงเดือนที่เลือก) พร้อมยอด YTD
/// ภาษีซื้อรวม ใบซื้อ VAT, นำเข้าตามใบขน, VAT ค่าใช้จ่ายตู้ FCL และ VAT ค่าใช้จ่ายอื่นๆ
class VatSummaryCard extends StatelessWidget {
  final List<Sale> sales;
  final List<Purchase> purchases;
  final List<FclShipment> shipments;
  final List<Expense> expenses;
  final DateTime selectedMonth;

  const VatSummaryCard({
    Key? key,
    required this.sales,
    required this.purchases,
    required this.shipments,
    this.expenses = const [],
    required this.selectedMonth,
  }) : super(key: key);

  static const _thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

  List<_VatEntry> _entriesForYear(int year) {
    final entries = <_VatEntry>[];
    for (final sale in sales) {
      if (sale.saleDate.year != year) continue;
      final vat = TaxAmounts.saleVAT(sale);
      if (vat == 0) continue;
      entries.add(_VatEntry(
        date: sale.saleDate,
        kind: 'ขาย',
        code: sale.saleCode,
        partner: sale.customerName,
        vat: vat,
        isSale: true,
      ));
    }
    for (final purchase in purchases) {
      if (purchase.purchaseDate.year != year) continue;
      final vat = TaxAmounts.purchaseVAT(purchase);
      if (vat == 0) continue;
      final declarationNo = purchase.importCustoms?.declarationNo ?? '';
      entries.add(_VatEntry(
        date: purchase.purchaseDate,
        kind: purchase.isImport ? 'นำเข้า' : 'ซื้อ',
        code: declarationNo.isNotEmpty ? '${purchase.purchaseCode} · ใบขน $declarationNo' : purchase.purchaseCode,
        partner: purchase.supplierName,
        vat: vat,
        isSale: false,
      ));
    }
    for (final shipment in shipments) {
      for (final line in shipment.costLines) {
        if (line.vat == 0) continue;
        final date = TaxAmounts.fclLineVATDate(shipment, line);
        if (date.year != year) continue;
        entries.add(_VatEntry(
          date: date,
          kind: 'ค่าตู้',
          code: [
            shipment.fclCode,
            line.name,
            if (line.taxInvoiceNo.isNotEmpty) line.taxInvoiceNo,
          ].join(' · '),
          partner: line.vendor,
          vat: line.vat,
          isSale: false,
        ));
      }
    }
    for (final expense in expenses) {
      if (expense.vat == 0 || expense.expenseDate.year != year) continue;
      entries.add(_VatEntry(
        date: expense.expenseDate,
        kind: 'ค่าใช้จ่าย',
        code: [
          expense.category,
          if (expense.description.isNotEmpty) expense.description,
          if (expense.taxInvoiceNo.isNotEmpty) expense.taxInvoiceNo,
        ].join(' · '),
        partner: expense.vendor,
        vat: expense.vat,
        isSale: false,
      ));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final year = selectedMonth.year;
    final lastMonth = selectedMonth.month;
    final entries = _entriesForYear(year);
    final money = NumberFormat('#,##0.00');

    final saleVAT = List<double>.filled(13, 0);
    final purchaseVAT = List<double>.filled(13, 0);
    for (final e in entries) {
      if (e.isSale) {
        saleVAT[e.date.month] += e.vat;
      } else {
        purchaseVAT[e.date.month] += e.vat;
      }
    }

    double ytdSale = 0, ytdPurchase = 0;
    for (int m = 1; m <= lastMonth; m++) {
      ytdSale += saleVAT[m];
      ytdPurchase += purchaseVAT[m];
    }

    String net(double v) => v < 0 ? '(${money.format(-v)})' : money.format(v);
    Color netColor(double v) => v < 0 ? Colors.green[700]! : Colors.red[700]!;

    DataRow monthRow(int m) {
      final isSelected = m == lastMonth;
      final n = saleVAT[m] - purchaseVAT[m];
      final style = TextStyle(fontWeight: isSelected ? FontWeight.bold : null);
      return DataRow(
        color: isSelected ? WidgetStatePropertyAll(Colors.blue[50]) : null,
        onSelectChanged: (_) => _showMonthDetail(context, entries, year, m),
        cells: [
          DataCell(Text('${_thaiMonths[m - 1]}${isSelected ? ' ◀' : ''}', style: style)),
          DataCell(Text(money.format(saleVAT[m]), style: style)),
          DataCell(Text(money.format(purchaseVAT[m]), style: style)),
          DataCell(Text(net(n), style: style.copyWith(color: netColor(n)))),
        ],
      );
    }

    final ytdNet = ytdSale - ytdPurchase;
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Colors.teal),
                const SizedBox(width: 8),
                Text('สรุป VAT ปี ${year + 543}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('เดือน')),
                  DataColumn(label: Text('ภาษีขาย'), numeric: true),
                  DataColumn(label: Text('ภาษีซื้อ'), numeric: true),
                  DataColumn(label: Text('ต้องชำระ/(เครดิต)'), numeric: true),
                ],
                rows: [
                  for (int m = lastMonth; m >= 1; m--) monthRow(m),
                  DataRow(cells: [
                    DataCell(Text('YTD (ม.ค.–${_thaiMonths[lastMonth - 1]})', style: bold)),
                    DataCell(Text(money.format(ytdSale), style: bold)),
                    DataCell(Text(money.format(ytdPurchase), style: bold)),
                    DataCell(Text(net(ytdNet), style: bold.copyWith(color: netColor(ytdNet)))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ภาษีซื้อรวมใบซื้อ VAT, นำเข้าตามใบขน, VAT ค่าใช้จ่ายตู้ และค่าใช้จ่ายที่มีใบกำกับภาษี · กดที่เดือนเพื่อดูรายการ\n'
              'ตัวเลขนี้ใช้ดูภาพรวม ยอดยื่น ภ.พ.30 ให้ยึดตามบัญชี',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthDetail(BuildContext context, List<_VatEntry> entries, int year, int month) {
    final money = NumberFormat('#,##0.00');
    final monthEntries = entries.where((e) => e.date.month == month).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Color kindColor(String kind) => switch (kind) {
          'ขาย' => Colors.green,
          'นำเข้า' => Colors.teal,
          'ค่าตู้' => Colors.indigo,
          'ค่าใช้จ่าย' => Colors.deepOrange,
          _ => Colors.blue,
        };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('รายการ VAT ${_thaiMonths[month - 1]} ${year + 543}'),
        content: SizedBox(
          width: 600,
          child: monthEntries.isEmpty
              ? const Text('ไม่มีรายการที่มี VAT')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: monthEntries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = monthEntries[i];
                    return ListTile(
                      dense: true,
                      leading: Chip(
                        label: Text(e.kind, style: const TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: kindColor(e.kind),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      title: Text(e.code, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${DateFormatter.formatDate(e.date)}${e.partner.isNotEmpty ? ' · ${e.partner}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${e.isSale ? '' : '−'}${money.format(e.vat)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: e.isSale ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
        ],
      ),
    );
  }
}
