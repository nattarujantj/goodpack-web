import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/deposit.dart';
import 'package:flutter_app/models/purchase.dart';
import 'package:flutter_app/models/sale.dart';

void main() {
  test('Deposit parses balance and usage history', () {
    final d = Deposit.fromJson({
      'id': 'd1',
      'depositCode': 'DP-6911-0001',
      'type': 'supplier',
      'partyId': 's1',
      'partyName': 'โรงงาน A',
      'amount': 100000,
      'depositDate': '2026-11-01T00:00:00Z',
      'usedAmount': 30000,
      'remainingAmount': 70000,
      'usages': [
        {'docType': 'purchase', 'docId': 'p1', 'docCode': 'PO-0001', 'docDate': '2026-11-02T00:00:00Z', 'amount': 30000},
      ],
    });
    expect(d.isCustomer, isFalse);
    expect(d.remainingAmount, 70000);
    expect(d.isFullyUsed, isFalse);
    expect(d.usages.single.docCode, 'PO-0001');
  });

  test('Purchase reads deposit applications and amount due', () {
    final p = Purchase.fromJson({
      'id': 'p1',
      'grandTotal': 107000,
      'deposit': 70000,
      'depositApplications': [
        {'depositId': 'd1', 'depositCode': 'DP-6911-0001', 'amount': 70000},
      ],
      'payment': {'isPaid': false},
      'warehouse': {'isUpdated': false},
    });
    expect(p.depositApplications.single.depositCode, 'DP-6911-0001');
    expect(p.amountDue, 37000);
  });

  test('old documents without depositApplications parse as empty', () {
    expect(DepositApplication.listFromJson(null), isEmpty);
  });

  test('VAT deposit amounts split before VAT / VAT / total', () {
    final ex = Deposit.calculateVAT(10000, true, 'exclusive');
    expect([ex.beforeVAT, ex.vat, ex.total], [10000, 700, 10700]);
    final inc = Deposit.calculateVAT(10700, true, 'inclusive');
    expect([inc.beforeVAT, inc.vat, inc.total], [10000, 700, 10700]);
    final none = Deposit.calculateVAT(5000, false, '');
    expect([none.beforeVAT, none.vat, none.total], [5000, 0, 5000]);
  });

  test('VAT deposit is deducted before VAT on the sale', () {
    final t = SaleTotals.calculate(itemsTotal: 100000, isVAT: true, vatType: 'exclusive', depositBeforeVAT: 10000);
    expect(t.netBeforeVAT, 90000);
    expect(t.vat, 6300);
    expect(t.afterVAT, 96300);
    final noDeposit = SaleTotals.calculate(itemsTotal: 107000, isVAT: true, vatType: 'inclusive');
    expect(noDeposit.vat, 7000);
    expect(noDeposit.afterVAT, 107000);
  });

  test('application split before/after VAT', () {
    const apps = [
      DepositApplication(depositId: 'a', amount: 10000, beforeVAT: true),
      DepositApplication(depositId: 'b', amount: 5000),
    ];
    expect(DepositApplication.sumBeforeVAT(apps), 10000);
    expect(DepositApplication.sumAfterVAT(apps), 5000);
  });

  test('VAT inclusive deposit split over two VAT inclusive sales ends at zero', () {
    final dep = Deposit.calculateVAT(10000, true, 'inclusive'); // ก่อน VAT 9,345.79
    final need = SaleTotals.calculate(itemsTotal: 5000, isVAT: true, vatType: 'inclusive').itemsBeforeVAT;
    final remainingAfterFirst = dep.beforeVAT - need;
    // ใบที่สองต้องการมากกว่ายอดคงเหลือ 1 สตางค์ แต่ยังอยู่ในเกณฑ์ปัดเศษ
    expect(need - remainingAfterFirst, lessThanOrEqualTo(Deposit.roundingTolerance));
    final second = SaleTotals.calculate(itemsTotal: 5000, isVAT: true, vatType: 'inclusive', depositBeforeVAT: need);
    expect(second.afterVAT, 0);
    final full = SaleTotals.calculate(itemsTotal: 10000, isVAT: true, vatType: 'inclusive', depositBeforeVAT: dep.beforeVAT);
    expect(full.afterVAT, 0);
  });
}
