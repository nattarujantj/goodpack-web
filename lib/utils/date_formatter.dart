import 'package:intl/intl.dart';

class DateFormatter {
  // Thailand timezone offset (GMT+7)
  static const Duration thailandOffset = Duration(hours: 7);

  /// Convert UTC DateTime to Thailand timezone
  static DateTime toThailand(DateTime dateTime) {
    // If already local, convert to UTC first
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    // Add Thailand offset
    return utc.add(thailandOffset);
  }

  /// Format DateTime to Thai format (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm').format(thaiTime);
  }

  /// Format DateTime to Thai format with seconds (dd/MM/yyyy HH:mm:ss)
  static String formatDateTimeWithSeconds(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(thaiTime);
  }

  /// Format DateTime to date only (dd/MM/yyyy)
  static String formatDate(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    return DateFormat('dd/MM/yyyy').format(thaiTime);
  }

  /// Format DateTime to time only (HH:mm)
  static String formatTime(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    return DateFormat('HH:mm').format(thaiTime);
  }

  /// Format DateTime to Thai Buddhist year format (dd/MM/พ.ศ. HH:mm)
  static String formatThaiDateTime(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    final buddhistYear = thaiTime.year + 543;
    return '${thaiTime.day.toString().padLeft(2, '0')}/${thaiTime.month.toString().padLeft(2, '0')}/$buddhistYear ${thaiTime.hour.toString().padLeft(2, '0')}:${thaiTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to Thai Buddhist year date only (dd/MM/พ.ศ.)
  static String formatThaiDate(DateTime dateTime) {
    final thaiTime = toThailand(dateTime);
    final buddhistYear = thaiTime.year + 543;
    return '${thaiTime.day.toString().padLeft(2, '0')}/${thaiTime.month.toString().padLeft(2, '0')}/$buddhistYear';
  }
}

