// Uses dart:html through the models, so run in a browser:
//   flutter test --platform chrome test/tax_summary_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/bank_account.dart';
import 'package:flutter_app/models/expense.dart';
import 'package:flutter_app/models/fcl_shipment.dart';
import 'package:flutter_app/models/purchase.dart';
import 'package:flutter_app/models/sale.dart';
import 'package:flutter_app/utils/tax_amounts.dart';
import 'package:flutter_app/widgets/bank_account_summary_card.dart';
import 'package:flutter_app/widgets/vat_summary_card.dart';

Sale sale({
  required String code,
  required String date,
  required double items,
  bool isVAT = true,
  String vatType = 'exclusive',
  double shipping = 0,
  bool paid = false,
  String? account,
}) {
  return Sale.fromJson({
    'id': code,
    'saleCode': code,
    'saleDate': date,
    'customerId': 'c1',
    'customerName': 'ลูกค้า',
    'items': [
      {'productId': 'p1', 'productName': 'A', 'productCode': 'A', 'quantity': 1, 'unitPrice': items, 'totalPrice': items},
    ],
    'isVAT': isVAT,
    'vatType': vatType,
    'shippingCost': shipping,
    'payment': {'isPaid': paid, 'ourAccount': account, 'paymentDate': date},
    'warehouse': {'isUpdated': false, 'actualShipping': 0, 'items': []},
    'createdAt': date,
    'updatedAt': date,
  });
}

Purchase purchase({
  required String code,
  required String date,
  required double amount,
  required double vat,
  bool isVAT = true,
  String vatType = 'exclusive',
  double shipping = 0,
  bool paid = false,
  String? account,
}) {
  return Purchase.fromJson({
    'id': code,
    'purchaseCode': code,
    'purchaseDate': date,
    'supplierId': 's1',
    'supplierName': 'ซัพ',
    'items': [],
    'isVAT': isVAT,
    'vatType': vatType,
    'shippingCost': shipping,
    'payment': {'isPaid': paid, 'ourAccount': account, 'paymentDate': date},
    'warehouse': {'isUpdated': false, 'actualShipping': 0, 'items': []},
    'totalAmount': amount,
    'totalVAT': vat,
    'grandTotal': vatType == 'inclusive' ? amount : amount + vat,
    'createdAt': date,
    'updatedAt': date,
  });
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('TaxAmounts', () {
    test('expense before VAT', () {
      final e = Expense.fromJson({'id': 'e1', 'category': 'x', 'amount': 1070, 'vat': 70, 'expenseDate': '2026-10-08T00:00:00Z'});
      expect(e.amountBeforeVAT, 1000);
      final old = Expense.fromJson({'id': 'e2', 'category': 'x', 'amount': 500, 'expenseDate': '2026-10-08T00:00:00Z'});
      expect(old.amountBeforeVAT, 500); // records saved before VAT existed
    });

    test('sale VAT นอก: VAT on items only, shipping not taxed', () {
      final s = sale(code: 'S1', date: '2026-10-05T00:00:00Z', items: 1000, shipping: 50);
      expect(TaxAmounts.saleVAT(s), 70);
      expect(TaxAmounts.saleBeforeVAT(s), 1050);
      expect(TaxAmounts.saleGrandTotal(s), 1120);
    });

    test('sale VAT ใน: VAT extracted from price', () {
      final s = sale(code: 'S2', date: '2026-10-05T00:00:00Z', items: 1070, vatType: 'inclusive');
      expect(TaxAmounts.saleVAT(s), closeTo(70, 0.001));
      expect(TaxAmounts.saleBeforeVAT(s), closeTo(1000, 0.001));
    });

    test('non-VAT sale has no VAT', () {
      final s = sale(code: 'S3', date: '2026-10-05T00:00:00Z', items: 500, isVAT: false);
      expect(TaxAmounts.saleVAT(s), 0);
      expect(TaxAmounts.saleBeforeVAT(s), 500);
    });

    test('import purchase uses stored customs VAT', () {
      final p = purchase(code: 'P1', date: '2026-10-02T00:00:00Z', amount: 60000, vat: 4270, vatType: 'import', shipping: 100);
      expect(TaxAmounts.purchaseVAT(p), 4270);
      expect(TaxAmounts.purchaseBeforeVAT(p), 60100);
      expect(TaxAmounts.purchaseGrandTotal(p), 64370);
    });

    test('VAT ใน purchase before VAT', () {
      final p = purchase(code: 'P2', date: '2026-10-02T00:00:00Z', amount: 1070, vat: 70, vatType: 'inclusive');
      expect(TaxAmounts.purchaseBeforeVAT(p), 1000);
    });
  });

  testWidgets('VatSummaryCard sums sales, purchases, imports and container VAT per month', (tester) async {
    final shipment = FclShipment.fromJson({
      'id': 'f1',
      'fclCode': 'FCL-1',
      'shipmentDate': '2026-09-20T00:00:00Z',
      'costLines': [
        {'name': 'THC', 'currency': 'THB', 'amount': 6500, 'vat': 455, 'taxInvoiceDate': '2026-10-05T00:00:00Z'},
      ],
    });
    await tester.pumpWidget(wrap(VatSummaryCard(
      sales: [
        sale(code: 'S1', date: '2026-10-05T00:00:00Z', items: 100000), // VAT 7,000
        sale(code: 'S0', date: '2026-09-10T00:00:00Z', items: 10000), // VAT 700
      ],
      purchases: [
        purchase(code: 'P1', date: '2026-10-02T00:00:00Z', amount: 300000, vat: 22167, vatType: 'import'),
        purchase(code: 'P2', date: '2026-10-03T00:00:00Z', amount: 10000, vat: 700),
      ],
      shipments: [shipment],
      expenses: [
        Expense.fromJson({'id': 'e1', 'category': 'ค่าขนส่ง', 'amount': 1070, 'vat': 70, 'expenseDate': '2026-10-08T00:00:00Z'}),
        Expense.fromJson({'id': 'e2', 'category': 'ค่าน้ำมัน', 'amount': 500, 'expenseDate': '2026-10-08T00:00:00Z'}),
      ],
      selectedMonth: DateTime(2026, 10),
    )));

    // ต.ค.: ภาษีซื้อ 22,167 + 700 + 455 + 70 = 23,392 → เครดิต 16,392
    expect(find.text('7,000.00'), findsOneWidget);
    expect(find.text('23,392.00'), findsNWidgets(2)); // ต.ค. and YTD (no purchases in ก.ย.)
    expect(find.text('(16,392.00)'), findsOneWidget);
    // YTD: ขาย 7,700 ซื้อ 23,392 → เครดิต 15,692
    expect(find.text('7,700.00'), findsOneWidget);
    expect(find.text('(15,692.00)'), findsOneWidget);
  });

  testWidgets('BankAccountSummaryCard counts paid money in/out per account', (tester) async {
    final accounts = [
      BankAccount(id: 'k1', bankName: 'KBank', bankAccountName: 'บัญชีหลัก', accountNumber: '1234567890'),
    ];
    await tester.pumpWidget(wrap(BankAccountSummaryCard(
      sales: [
        sale(code: 'S1', date: '2026-10-05T00:00:00Z', items: 1000, paid: true, account: 'k1'), // 1,070
        sale(code: 'S2', date: '2026-10-06T00:00:00Z', items: 2000, paid: true, account: 'k1'), // 2,140
        sale(code: 'S3', date: '2026-10-07T00:00:00Z', items: 5000, paid: false, account: 'k1'), // not paid
        sale(code: 'S4', date: '2026-09-07T00:00:00Z', items: 1000, paid: true, account: 'k1'), // last month
      ],
      purchases: [
        purchase(code: 'P1', date: '2026-10-02T00:00:00Z', amount: 1000, vat: 70, paid: true, account: 'k1'),
      ],
      accounts: accounts,
      selectedMonth: DateTime(2026, 10),
    )));

    expect(find.textContaining('KBank บัญชีหลัก (…7890)'), findsOneWidget);
    expect(find.text('3,210.00'), findsNWidgets(2)); // account row + total row
    expect(find.text('1,070.00'), findsNWidgets(2));

    await tester.tap(find.text('ทั้งปี'));
    await tester.pumpAndSettle();
    expect(find.text('4,280.00'), findsNWidgets(2)); // includes September
  });
}
