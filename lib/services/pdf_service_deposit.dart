import 'dart:html' as html;
import '../models/bank_account.dart';
import '../models/customer.dart';
import '../models/deposit.dart';
import '../models/sale.dart';
import 'config_service.dart';
import 'pdf_service_sale.dart';

/// พิมพ์ใบรับเงินมัดจำจากรายการมัดจำของลูกค้า
/// - มัดจำ VAT: "ใบรับเงินมัดจำ/ใบกำกับภาษี"
/// - มัดจำไม่มี VAT: "ใบรับเงินมัดจำ"
/// ใช้รูปแบบเอกสารเดียวกับใบกำกับภาษีของรายการขาย
class PdfServiceDeposit {
  PdfServiceDeposit._();

  static SaleDocumentType documentTypeFor(Deposit deposit) =>
      deposit.isVAT ? SaleDocumentType.depositTaxInvoice : SaleDocumentType.depositReceipt;

  /// รายละเอียดในตารางรายการ เช่น "เงินมัดจำค่าสินค้า ตาม PO-123"
  static String itemDescription(Deposit deposit) {
    final parts = <String>['เงินมัดจำค่าสินค้า'];
    if (deposit.reference.isNotEmpty) parts.add('ตาม ${deposit.reference}');
    return parts.join(' ');
  }

  /// แปลงมัดจำเป็นเอกสารแบบใบขาย 1 รายการ เพื่อใช้ตัวสร้าง PDF เดียวกับรายการขาย
  static Sale toSaleDocument(Deposit deposit, Customer? customer) {
    // VAT ใน: ใช้ยอดรวม VAT และสูตร VAT ใน เพื่อให้ VAT ตรงกับที่บันทึกไว้
    final inclusive = deposit.isVAT && deposit.vatType == 'inclusive';
    final price = !deposit.isVAT ? deposit.amount : (inclusive ? deposit.amount : deposit.amountBeforeVAT);
    String? nonEmpty(String? v) => (v == null || v.trim().isEmpty) ? null : v;

    return Sale(
      id: deposit.id,
      saleCode: deposit.depositCode,
      saleDate: deposit.depositDate,
      customerId: deposit.partyId,
      customerName: (customer?.companyName.isNotEmpty ?? false) ? customer!.companyName : deposit.partyName,
      contactName: nonEmpty(customer?.contactName),
      customerCode: nonEmpty(customer?.customerCode) ?? nonEmpty(deposit.partyCode),
      taxId: nonEmpty(customer?.taxId),
      address: nonEmpty(customer?.address),
      phone: nonEmpty(customer?.phone),
      items: [
        SaleItem(
          productId: '',
          productName: itemDescription(deposit),
          productCode: '',
          quantity: 1,
          unitPrice: price,
          totalPrice: price,
        ),
      ],
      isVAT: deposit.isVAT,
      vatType: inclusive ? 'inclusive' : 'exclusive',
      shippingCost: 0,
      payment: PaymentInfo(
        isPaid: true,
        ourAccount: deposit.ourAccount,
        paymentDate: deposit.depositDate,
      ),
      warehouse: WarehouseInfo(isUpdated: false, actualShipping: 0, items: const []),
      notes: deposit.notes.isEmpty ? null : deposit.notes,
      createdAt: deposit.createdAt,
      updatedAt: deposit.updatedAt,
    );
  }

  /// บัญชีที่รับเงินมัดจำ (จาก config) สำหรับแสดงในช่องธนาคาร
  static Future<BankAccount?> bankAccountFor(Deposit deposit) async {
    final id = deposit.ourAccount;
    if (id == null || id.isEmpty) return null;
    final config = ConfigService();
    if (!config.isLoaded) await config.loadConfig();
    for (final a in config.accounts) {
      if (a.id == id) {
        return BankAccount(
          id: a.id,
          bankName: a.bankName,
          bankAccountName: a.name,
          accountNumber: a.accountNumber,
        );
      }
    }
    return null;
  }

  static Future<void> printDeposit(
    Deposit deposit,
    Customer? customer, {
    String? signerName,
    html.WindowBase? targetWindow,
  }) async {
    await PdfServiceSale.generateAndPrintSale(
      toSaleDocument(deposit, customer),
      documentTypeFor(deposit),
      bankAccount: await bankAccountFor(deposit),
      signerName: signerName,
      targetWindow: targetWindow,
    );
  }
}
