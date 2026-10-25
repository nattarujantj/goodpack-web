import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../utils/tax_amounts.dart';

/// ยอดเข้า-ออกของหนึ่งบัญชี
class _AccountFlow {
  final String label;
  int inCount = 0;
  double inAmount = 0;
  int outCount = 0;
  double outAmount = 0;

  _AccountFlow(this.label);
}

/// สรุปจำนวนครั้งและยอดเงินเข้า-ออกของแต่ละบัญชีธนาคาร (เดือนที่เลือก หรือทั้งปีถึงเดือนที่เลือก)
/// เงินเข้า = ใบขายที่ชำระแล้ว (ยอดรวม VAT), เงินออก = ใบซื้อที่ชำระแล้ว (ยอดรวม VAT + ค่าส่ง)
/// นับตามวันที่ชำระ ถ้าไม่ได้กรอกใช้วันที่เอกสาร
class BankAccountSummaryCard extends StatefulWidget {
  final List<Sale> sales;
  final List<Purchase> purchases;
  final List<BankAccount> accounts;
  final DateTime selectedMonth;

  const BankAccountSummaryCard({
    Key? key,
    required this.sales,
    required this.purchases,
    required this.accounts,
    required this.selectedMonth,
  }) : super(key: key);

  @override
  State<BankAccountSummaryCard> createState() => _BankAccountSummaryCardState();
}

class _BankAccountSummaryCardState extends State<BankAccountSummaryCard> {
  static const _thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  static const _unassigned = '';

  bool _wholeYear = false;

  bool _inPeriod(DateTime date) {
    final sel = widget.selectedMonth;
    if (date.year != sel.year) return false;
    return _wholeYear ? date.month <= sel.month : date.month == sel.month;
  }

  String _accountLabel(String id, BankAccount? snapshot) {
    if (id == _unassigned) return 'ไม่ระบุบัญชี';
    BankAccount? account;
    for (final a in widget.accounts) {
      if (a.id == id) {
        account = a;
        break;
      }
    }
    account ??= snapshot;
    if (account == null) return id;
    final number = account.accountNumber;
    final tail = number.length > 4 ? number.substring(number.length - 4) : number;
    return '${account.bankName} ${account.bankAccountName}${tail.isNotEmpty ? ' (…$tail)' : ''}';
  }

  Map<String, _AccountFlow> _flows() {
    final flows = <String, _AccountFlow>{};
    _AccountFlow flowFor(String? id, BankAccount? snapshot) {
      final key = (id == null || id.isEmpty) ? _unassigned : id;
      return flows.putIfAbsent(key, () => _AccountFlow(_accountLabel(key, snapshot)));
    }

    for (final sale in widget.sales) {
      if (!sale.payment.isPaid) continue;
      if (!_inPeriod(sale.payment.paymentDate?.toLocal() ?? sale.saleDate)) continue;
      final flow = flowFor(sale.payment.ourAccount, sale.payment.ourAccountInfo);
      flow.inCount++;
      flow.inAmount += TaxAmounts.saleGrandTotal(sale);
    }
    for (final purchase in widget.purchases) {
      if (!purchase.payment.isPaid) continue;
      if (!_inPeriod(purchase.payment.paymentDate?.toLocal() ?? purchase.purchaseDate)) continue;
      final flow = flowFor(purchase.payment.ourAccount, null);
      flow.outCount++;
      flow.outAmount += TaxAmounts.purchaseGrandTotal(purchase);
    }
    return flows;
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');
    final sel = widget.selectedMonth;
    final flows = _flows().entries.toList()
      ..sort((a, b) {
        // บัญชีที่ไม่ระบุไว้ท้ายสุด, ที่เหลือเรียงตามจำนวนครั้งที่ใช้
        if (a.key == _unassigned) return 1;
        if (b.key == _unassigned) return -1;
        return (b.value.inCount + b.value.outCount).compareTo(a.value.inCount + a.value.outCount);
      });

    final total = _AccountFlow('รวม');
    for (final f in flows) {
      total.inCount += f.value.inCount;
      total.inAmount += f.value.inAmount;
      total.outCount += f.value.outCount;
      total.outAmount += f.value.outAmount;
    }

    DataRow row(_AccountFlow f, {bool bold = false}) {
      final style = TextStyle(fontWeight: bold ? FontWeight.bold : null);
      final net = f.inAmount - f.outAmount;
      return DataRow(cells: [
        DataCell(ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(f.label, style: style, overflow: TextOverflow.ellipsis),
        )),
        DataCell(Text('${f.inCount}', style: style)),
        DataCell(Text(money.format(f.inAmount), style: style.copyWith(color: Colors.green[700]))),
        DataCell(Text('${f.outCount}', style: style)),
        DataCell(Text(money.format(f.outAmount), style: style.copyWith(color: Colors.red[700]))),
        DataCell(Text(money.format(net), style: style.copyWith(color: net < 0 ? Colors.red[700] : null))),
      ]);
    }

    final periodLabel = _wholeYear
        ? 'ปี ${sel.year + 543} (ม.ค.–${_thaiMonths[sel.month - 1]})'
        : '${_thaiMonths[sel.month - 1]} ${sel.year + 543}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text('เงินเข้า-ออกตามบัญชี · $periodLabel',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('เดือน')),
                    ButtonSegment(value: true, label: Text('ทั้งปี')),
                  ],
                  selected: {_wholeYear},
                  onSelectionChanged: (v) => setState(() => _wholeYear = v.first),
                ),
              ],
            ),
            const Divider(),
            if (flows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('ไม่มีรายการที่ชำระแล้วในช่วงนี้', style: TextStyle(color: Colors.grey)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('บัญชี')),
                    DataColumn(label: Text('เข้า (ครั้ง)'), numeric: true),
                    DataColumn(label: Text('ยอดเข้า'), numeric: true),
                    DataColumn(label: Text('ออก (ครั้ง)'), numeric: true),
                    DataColumn(label: Text('ยอดออก'), numeric: true),
                    DataColumn(label: Text('สุทธิ'), numeric: true),
                  ],
                  rows: [
                    for (final f in flows) row(f.value),
                    row(total, bold: true),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'เข้า = ใบขายที่ชำระแล้ว · ออก = ใบซื้อที่ชำระแล้ว (ยอดรวม VAT และค่าส่ง) · นับตามวันที่ชำระ\n'
              'ยังไม่รวมค่าใช้จ่ายอื่นๆ เพราะหน้าค่าใช้จ่ายยังไม่มีช่องเลือกบัญชี',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
