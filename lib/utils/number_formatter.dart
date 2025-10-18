import 'package:intl/intl.dart';

class NumberFormatter {
  // Format quantity: x,xxx (มี comma คั่นหลักพัน)
  static String formatQuantity(int quantity) {
    final formatter = NumberFormat('#,###');
    return formatter.format(quantity);
  }

  // Format price: xx,xxx.xx (มี comma คั่นหลักพัน และทศนิยม 2 ตำแหน่ง)
  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###.00');
    return formatter.format(price);
  }

  // Format price with currency symbol
  static String formatPriceWithCurrency(double price) {
    return '฿${formatPrice(price)}';
  }

  // Format quantity with unit
  static String formatQuantityWithUnit(int quantity, {String unit = 'ชิ้น'}) {
    return '${formatQuantity(quantity)} $unit';
  }
}
