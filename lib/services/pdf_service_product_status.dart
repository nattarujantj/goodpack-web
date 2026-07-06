import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../models/product.dart';

/// สร้างและพิมพ์รายการสินค้าตามสถานะที่เลือก (A4 แนวนอน, แบ่งหน้าอัตโนมัติ)
class PdfServiceProductStatus {
  static Future<void> generateAndPrintProductStatusList(
    List<Product> products, {
    required Set<String> statuses,
  }) async {
    try {
      final filtered = products.where((p) => statuses.contains(p.status)).toList();
      final pdf = await _createProductStatusPdf(filtered, statuses);
      final pdfBytes = await pdf.save();

      // เปิด PDF ใน tab ใหม่สำหรับ Web
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
      } else {
        // สำหรับ mobile/desktop ใช้ Printing.sharePdf เพื่อให้สามารถดาวน์โหลดหรือแชร์ไฟล์ได้
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'รายการสินค้า.pdf',
        );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<pw.Document> _createProductStatusPdf(List<Product> products, Set<String> statuses) async {
    final pdf = pw.Document();

    const double fontSizeText = 11.0;

    // โหลดฟอนต์ไทย (ใช้ fallback chain เดียวกับ pdf_service_sale.dart)
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

    // เรียงลำดับเดียวกับหน้าจอ: active ก่อน inactive แล้วเรียงตาม skuId
    final sorted = List<Product>.from(products)
      ..sort((a, b) {
        final aRank = a.status == 'inactive' ? 1 : 0;
        final bRank = b.status == 'inactive' ? 1 : 0;
        final rankComparison = aRank - bRank;
        if (rankComparison != 0) return rankComparison;
        return a.skuId.compareTo(b.skuId);
      });

    final statusLabel = _statusFilterLabel(statuses);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) => _buildHeader(context, thaiFont, statusLabel, fontSizeText),
        build: (pw.Context context) => [
          _buildProductTable(sorted, thaiFont, fontSizeText),
        ],
      ),
    );

    return pdf;
  }

  static String _statusFilterLabel(Set<String> statuses) {
    if (statuses.length == 2) return 'ทั้งหมด';
    if (statuses.contains('active')) return 'ใช้งาน';
    if (statuses.contains('inactive')) return 'ไม่ใช้งาน';
    return '-';
  }

  static pw.Widget _buildHeader(pw.Context context, pw.Font? thaiFont, String statusLabel, double fontSizeText) {
    final pageNum = context.pageNumber;
    final pagesCount = context.pagesCount;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'รายการสินค้า (สถานะ: $statusLabel)',
              style: pw.TextStyle(font: thaiFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'หน้า $pageNum / $pagesCount',
              style: pw.TextStyle(font: thaiFont, fontSize: 11),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        // หัวตาราง render ในส่วน header ของทุกหน้า -> อยู่บนสุดเสมอและตรงคอลัมน์กับข้อมูล
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: _columnWidths(),
          children: [_tableHeaderRow(thaiFont, fontSizeText)],
        ),
      ],
    );
  }

  /// ความกว้างคอลัมน์ (ใช้ร่วมกันระหว่างตารางหัวใน header และตารางข้อมูลใน body
  /// เพื่อให้คอลัมน์ตรงกัน). คอลัมน์สุดท้ายเป็นช่องว่างสำหรับเขียนโน้ต จึงได้พื้นที่มากสุด.
  static Map<int, pw.TableColumnWidth> _columnWidths() => {
        0: const pw.FlexColumnWidth(2), // SKU ID
        1: const pw.FlexColumnWidth(4), // ชื่อสินค้า
        2: const pw.FlexColumnWidth(1.6), // VAT คงเหลือ
        3: const pw.FlexColumnWidth(1.8), // Non-VAT คงเหลือ
        4: const pw.FlexColumnWidth(1.6), // Actual Stock
        5: const pw.FlexColumnWidth(2.2), // จำนวนลังคงเหลือ
        6: const pw.FlexColumnWidth(5), // ช่องว่างสำหรับเขียนโน้ต
      };

  /// สร้างตารางข้อมูลเป็น Table เดียวต่อเนื่อง (ไม่มีแถวหัว) แล้วปล่อยให้ MultiPage
  /// ตัดหน้าตามแถวเองอัตโนมัติ -> ไม่มีปัญหาหัวตารางโผล่กลางหน้าจากการแบ่ง chunk
  static pw.Widget _buildProductTable(
    List<Product> products,
    pw.Font? thaiFont,
    double fontSizeText,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: _columnWidths(),
      children: products.map((product) {
        return pw.TableRow(
          children: [
            _tableCell(product.skuId, thaiFont, fontSizeText),
            _tableCell(product.name, thaiFont, fontSizeText),
            _tableCell(product.stock.vat.remaining.toString(), thaiFont, fontSizeText, right: true),
            _tableCell(product.stock.nonVAT.remaining.toString(), thaiFont, fontSizeText, right: true),
            _tableCell(product.stock.actualStock.toString(), thaiFont, fontSizeText, right: true),
            _tableCell(product.packRemainingText, thaiFont, fontSizeText, right: true),
            _tableCell('', thaiFont, fontSizeText), // ช่องว่างไว้เขียนโน้ต
          ],
        );
      }).toList(),
    );
  }

  static pw.TableRow _tableHeaderRow(pw.Font? thaiFont, double fontSizeText) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('SKU ID', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('ชื่อสินค้า', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('VAT คงเหลือ', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('Non-VAT คงเหลือ', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('Actual Stock', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('จำนวนลังคงเหลือ', thaiFont, fontSizeText, bold: true, center: true),
        _tableCell('', thaiFont, fontSizeText, bold: true, center: true), // ช่องว่างสำหรับเขียนโน้ต
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
      padding: const pw.EdgeInsets.all(2),
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
