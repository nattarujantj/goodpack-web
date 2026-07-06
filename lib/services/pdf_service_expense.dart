import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/expense.dart';

/// สร้างและพิมพ์รายงานค่าใช้จ่ายหลายเดือน (A4 แนวตั้ง)
/// ตารางต่อเนื่อง คั่นหัวข้อแต่ละเดือน + ยอดรวมต่อเดือน และท้ายเอกสารมีตารางสรุปยอดแต่ละเดือน
class PdfServiceExpense {
  static const _thaiMonthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  static final _currencyFormat = NumberFormat('#,##0.00');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// ป้ายชื่อเดือน + ปี พ.ศ. เช่น "มกราคม 2568"
  static String _monthLabel(int year, int month) =>
      '${_thaiMonthsFull[month - 1]} ${year + 543}';

  /// สร้างและพิมพ์รายงานค่าใช้จ่ายในช่วงเดือน [fromMonth]..[toMonth] (รวมปลายทั้งสอง)
  static Future<void> generateAndPrintExpenses(
    List<Expense> expenses, {
    required DateTime fromMonth,
    required DateTime toMonth,
  }) async {
    // ทำให้แน่ใจว่า from <= to (สลับให้ถูกต้องถ้าผู้ใช้เลือกกลับด้าน)
    final fromM = DateTime(fromMonth.year, fromMonth.month, 1);
    final toM = DateTime(toMonth.year, toMonth.month, 1);
    final loMonth = fromM.isAfter(toM) ? toM : fromM;
    final hiMonth = fromM.isAfter(toM) ? fromM : toM;
    final endExclusive = DateTime(hiMonth.year, hiMonth.month + 1, 1);

    final filtered = expenses
        .where((e) =>
            !e.expenseDate.isBefore(loMonth) && e.expenseDate.isBefore(endExclusive))
        .toList()
      ..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

    if (filtered.isEmpty) {
      throw Exception('ไม่มีรายการค่าใช้จ่ายในช่วงที่เลือก');
    }

    try {
      final pdf = await _createExpensePdf(filtered, loMonth, hiMonth);
      final pdfBytes = await pdf.save();

      // เปิด PDF ใน tab ใหม่สำหรับ Web
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
      } else {
        // สำหรับ mobile/desktop ใช้ Printing.sharePdf เพื่อให้ดาวน์โหลดหรือแชร์ไฟล์ได้
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'รายงานค่าใช้จ่าย.pdf',
        );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<pw.Document> _createExpensePdf(
    List<Expense> expenses,
    DateTime rangeStart,
    DateTime rangeToMonth,
  ) async {
    final pdf = pw.Document();

    const double fontSizeText = 11.0;

    // โหลดฟอนต์ไทย (ใช้ fallback chain เดียวกับ pdf_service_product_status.dart)
    pw.Font? thaiFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/CORDIA.ttf');
      thaiFont = pw.Font.ttf(fontData);
    } catch (e) {
      try {
        thaiFont = await PdfGoogleFonts.notoSansThaiRegular();
      } catch (e2) {
        try {
          thaiFont = await PdfGoogleFonts.kanitRegular();
        } catch (e3) {
          try {
            thaiFont = await PdfGoogleFonts.sarabunRegular();
          } catch (e4) {
            try {
              thaiFont = await PdfGoogleFonts.openSansRegular();
            } catch (e5) {
              print('ไม่พบฟอนต์ไทย ใช้ฟอนต์ default: $e5');
              thaiFont = null;
            }
          }
        }
      }
    }

    // จัดกลุ่มตามเดือน (year*100+month) เรียงจากเก่าไปใหม่
    final groups = <int, List<Expense>>{};
    for (final e in expenses) {
      final key = e.expenseDate.year * 100 + e.expenseDate.month;
      groups.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = groups.keys.toList()..sort();

    final rangeLabel = _rangeLabel(rangeStart, rangeToMonth);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) => _buildHeader(context, thaiFont, rangeLabel),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          for (final key in sortedKeys) {
            final year = key ~/ 100;
            final month = key % 100;
            final items = groups[key]!;
            final monthTotal = items.fold(0.0, (s, e) => s + e.amount);

            widgets.addAll(_buildMonthSection(
              _monthLabel(year, month),
              items,
              monthTotal,
              thaiFont,
              fontSizeText,
            ));
            widgets.add(pw.SizedBox(height: 12));
          }

          // ตารางสรุปยอดแต่ละเดือน + ยอดรวมทั้งหมด
          widgets.add(pw.SizedBox(height: 8));
          widgets.addAll(_buildSummarySection(groups, sortedKeys, thaiFont, fontSizeText));

          return widgets;
        },
      ),
    );

    return pdf;
  }

  static String _rangeLabel(DateTime start, DateTime toMonth) {
    final from = _monthLabel(start.year, start.month);
    final to = _monthLabel(toMonth.year, toMonth.month);
    return from == to ? from : '$from – $to';
  }

  static pw.Widget _buildHeader(pw.Context context, pw.Font? thaiFont, String rangeLabel) {
    final pageNum = context.pageNumber;
    final pagesCount = context.pagesCount;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'รายงานค่าใช้จ่าย',
                  style: pw.TextStyle(font: thaiFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ประจำเดือน $rangeLabel',
                  style: pw.TextStyle(font: thaiFont, fontSize: 11),
                ),
              ],
            ),
            pw.Text(
              'หน้า $pageNum / $pagesCount',
              style: pw.TextStyle(font: thaiFont, fontSize: 11),
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> get _columnWidths => const {
        0: pw.FlexColumnWidth(1.6), // วันที่
        1: pw.FlexColumnWidth(2.2), // หมวดหมู่
        2: pw.FlexColumnWidth(3.2), // รายละเอียด
        3: pw.FlexColumnWidth(2.4), // หมายเหตุ
        4: pw.FlexColumnWidth(1.8), // จำนวนเงิน
      };

  /// แถบหัวข้อ (พื้นสี) ใช้คั่นแต่ละเดือนและหัวข้อส่วนสรุป
  static pw.Widget _sectionTitle(String text, pw.Font? thaiFont) {
    return pw.Container(
      color: PdfColors.blueGrey100,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: thaiFont, fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// หัวข้อเดือน + ตารางรายการของเดือน + แถวยอดรวมเดือน
  /// คืนค่าเป็น List เพื่อให้ MultiPage แบ่งหน้าตารางที่ยาวเกินหนึ่งหน้าได้
  static List<pw.Widget> _buildMonthSection(
    String monthLabel,
    List<Expense> items,
    double monthTotal,
    pw.Font? thaiFont,
    double fontSizeText,
  ) {
    return [
      _sectionTitle(monthLabel, thaiFont),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black),
        columnWidths: _columnWidths,
        children: [
          _tableHeaderRow(thaiFont, fontSizeText),
          ...items.map((e) => pw.TableRow(
                children: [
                  _tableCell(_dateFormat.format(e.expenseDate), thaiFont, fontSizeText, center: true),
                  _tableCell(e.category, thaiFont, fontSizeText),
                  _tableCell(e.description, thaiFont, fontSizeText),
                  _tableCell(e.notes, thaiFont, fontSizeText),
                  _tableCell(_currencyFormat.format(e.amount), thaiFont, fontSizeText, right: true),
                ],
              )),
          // แถวยอดรวมเดือน
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              _tableCell('', thaiFont, fontSizeText),
              _tableCell('', thaiFont, fontSizeText),
              _tableCell('', thaiFont, fontSizeText),
              _tableCell('รวมเดือน $monthLabel', thaiFont, fontSizeText, bold: true, right: true),
              _tableCell(_currencyFormat.format(monthTotal), thaiFont, fontSizeText, bold: true, right: true),
            ],
          ),
        ],
      ),
    ];
  }

  /// ตารางสรุปยอดแต่ละเดือน + ยอดรวมทั้งหมด
  static List<pw.Widget> _buildSummarySection(
    Map<int, List<Expense>> groups,
    List<int> sortedKeys,
    pw.Font? thaiFont,
    double fontSizeText,
  ) {
    final grandTotal = groups.values
        .expand((l) => l)
        .fold(0.0, (s, e) => s + e.amount);

    return [
      _sectionTitle('สรุปยอดแต่ละเดือน', thaiFont),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black),
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _tableCell('เดือน', thaiFont, fontSizeText, bold: true, center: true),
              _tableCell('ยอดรวม (บาท)', thaiFont, fontSizeText, bold: true, center: true),
            ],
          ),
          ...sortedKeys.map((key) {
            final year = key ~/ 100;
            final month = key % 100;
            final total = groups[key]!.fold(0.0, (s, e) => s + e.amount);
            return pw.TableRow(
              children: [
                _tableCell(_monthLabel(year, month), thaiFont, fontSizeText),
                _tableCell(_currencyFormat.format(total), thaiFont, fontSizeText, right: true),
              ],
            );
          }),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              _tableCell('ยอดรวมทั้งหมด', thaiFont, fontSizeText, bold: true, right: true),
              _tableCell(_currencyFormat.format(grandTotal), thaiFont, fontSizeText, bold: true, right: true),
            ],
          ),
        ],
      ),
    ];
  }

  static pw.TableRow _tableHeaderRow(pw.Font? thaiFont, double fontSizeText) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('วันที่', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('หมวดหมู่', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('รายละเอียด', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('หมายเหตุ', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('จำนวนเงิน', thaiFont, fontSizeText, bold: true, center: true),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font? thaiFont,
    double fontSize, {
    bool bold = false,
    bool center = false,
    bool right = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          font: thaiFont,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
        textAlign: center ? pw.TextAlign.center : (right ? pw.TextAlign.right : pw.TextAlign.left),
      ),
    );
  }
}
