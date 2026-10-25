import '../models/fcl_shipment.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import 'number_formatter.dart';

/// ยอดก่อน VAT / VAT / ยอดรวม ของใบขายและใบซื้อ ใช้ร่วมกันในแดชบอร์ด
/// สูตรเดียวกับ backend: ใบขายคิด VAT จากยอดสินค้าเท่านั้น (ค่าส่งไม่คิด VAT)
class TaxAmounts {
  TaxAmounts._();

  static double saleItemsTotal(Sale sale) =>
      sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// ภาษีขายของใบขาย
  static double saleVAT(Sale sale) {
    if (!sale.isVAT) return 0;
    final items = saleItemsTotal(sale);
    if (sale.vatType == 'inclusive') {
      // VAT ใน: ราคารวม VAT แล้ว ถอด VAT ออก
      return items - roundTo2(items / 1.07);
    }
    return roundTo2(items * 0.07);
  }

  /// ยอดขายก่อน VAT (รวมค่าส่ง)
  static double saleBeforeVAT(Sale sale) {
    final items = saleItemsTotal(sale);
    final itemsBeforeVAT = sale.isVAT && sale.vatType == 'inclusive' ? items - saleVAT(sale) : items;
    return itemsBeforeVAT + sale.shippingCost;
  }

  /// ยอดเงินที่ลูกค้าต้องจ่าย (รวม VAT และค่าส่ง)
  static double saleGrandTotal(Sale sale) => saleBeforeVAT(sale) + saleVAT(sale);

  /// ราคาขายต่อชิ้นก่อน VAT
  static double saleUnitPriceBeforeVAT(Sale sale, SaleItem item) =>
      sale.isVAT && sale.vatType == 'inclusive' ? item.unitPrice / 1.07 : item.unitPrice;

  /// ภาษีซื้อของใบซื้อ (VAT นอก / VAT ใน / นำเข้าตามใบขน ใช้ยอดที่บันทึกไว้)
  static double purchaseVAT(Purchase purchase) => purchase.isVAT ? purchase.totalVAT : 0;

  /// ยอดซื้อก่อน VAT (รวมค่าส่ง)
  static double purchaseBeforeVAT(Purchase purchase) =>
      purchase.grandTotal - purchaseVAT(purchase) + purchase.shippingCost;

  /// ยอดเงินที่จ่ายจริงของใบซื้อ (รวม VAT และค่าส่ง)
  static double purchaseGrandTotal(Purchase purchase) => purchase.grandTotal + purchase.shippingCost;

  /// วันที่ลงภาษีซื้อของรายการค่าใช้จ่ายตู้: วันที่ใบกำกับ ถ้าไม่มีใช้วันที่ตู้
  static DateTime fclLineVATDate(FclShipment shipment, FclCostLine line) =>
      line.taxInvoiceDate ?? shipment.shipmentDate;
}
