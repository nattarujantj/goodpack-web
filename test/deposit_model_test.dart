import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/deposit.dart';
import 'package:flutter_app/models/purchase.dart';

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
}
