import '../models/fcl_shipment.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/deposit.dart';

/// ยอดก่อน VAT / VAT / ยอดรวม ของใบขายและใบซื้อ ใช้ร่วมกันในแดชบอร์ด
/// สูตรเดียวกับ backend: ใบขายคิด VAT จากยอดสินค้าเท่านั้น (ค่าส่งไม่คิด VAT)
class TaxAmounts {
  TaxAmounts._();

  static double saleItemsTotal(Sale sale) =>
      sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// ภาษีขายของใบขาย (หลังหักมัดจำที่ออกใบกำกับภาษีแล้ว ซึ่งลง VAT ไปตอนรับมัดจำ)
  static double saleVAT(Sale sale) => SaleTotals.ofSale(sale).vat;

  /// ยอดขายก่อน VAT (รวมค่าส่ง) = มูลค่าสินค้าเต็ม ไม่หักมัดจำ (ใช้ดูยอดขาย/รายได้)
  static double saleBeforeVAT(Sale sale) => SaleTotals.ofSale(sale).itemsBeforeVAT + sale.shippingCost;

  /// ยอดเงินที่ลูกค้าต้องจ่ายตามใบนี้ (รวม VAT และค่าส่ง) ก่อนหักมัดจำที่ไม่มี VAT
  static double saleGrandTotal(Sale sale) => SaleTotals.ofSale(sale).afterVAT + sale.shippingCost;

  /// เงินที่รับจริงตอนชำระใบขาย: หักมัดจำที่ผูกไว้ (เงินมัดจำนับเป็นเงินเข้าในวันที่รับมัดจำแล้ว)
  /// รายการเก่าที่กรอกมัดจำเองยังนับยอดเต็ม เพราะไม่มีรายการมัดจำให้นับแยก
  static double saleCashReceived(Sale sale) =>
      saleGrandTotal(sale) - DepositApplication.sumAfterVAT(sale.depositApplications);

  /// ราคาขายต่อชิ้นก่อน VAT
  static double saleUnitPriceBeforeVAT(Sale sale, SaleItem item) =>
      sale.isVAT && sale.vatType == 'inclusive' ? item.unitPrice / 1.07 : item.unitPrice;

  /// ภาษีซื้อของใบซื้อ (VAT นอก / VAT ใน / นำเข้าตามใบขน ใช้ยอดที่บันทึกไว้)
  static double purchaseVAT(Purchase purchase) => purchase.isVAT ? purchase.totalVAT : 0;

  /// ยอดซื้อก่อน VAT (รวมค่าส่ง) = มูลค่าสินค้าเต็ม ไม่หักมัดจำ
  static double purchaseBeforeVAT(Purchase purchase) =>
      purchase.grandTotal - purchaseVAT(purchase) + purchase.depositBeforeVAT + purchase.shippingCost;

  /// ยอดของใบซื้อ (รวม VAT และค่าส่ง) ก่อนหักมัดจำที่ไม่มี VAT
  static double purchaseGrandTotal(Purchase purchase) => purchase.grandTotal + purchase.shippingCost;

  /// เงินที่จ่ายจริงตอนชำระใบซื้อ: หักมัดจำที่ไม่มี VAT (เงินมัดจำนับเป็นเงินออกในวันที่วางมัดจำแล้ว)
  static double purchaseCashPaid(Purchase purchase) => purchaseGrandTotal(purchase) - purchase.deposit;

  /// วันที่ลงภาษีซื้อของรายการค่าใช้จ่ายตู้: วันที่ใบกำกับ ถ้าไม่มีใช้วันที่ตู้
  static DateTime fclLineVATDate(FclShipment shipment, FclCostLine line) =>
      line.taxInvoiceDate ?? shipment.shipmentDate;
}
