import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../models/quotation.dart';
import '../models/bank_account.dart';

class PdfServiceThaiEnhanced {
  static const String defaultSignerName = 'สุภาวดี บูรณะโอสถ';
  
  static Future<void> generateAndPrintQuotation(Quotation quotation, {BankAccount? bankAccount, String? signerName}) async {
    try {
      // สร้าง PDF document
      final pdf = await _createQuotationPdf(quotation, bankAccount: bankAccount, signerName: signerName ?? defaultSignerName);
      final pdfBytes = await pdf.save();
      
      // เปิด PDF ใน tab ใหม่สำหรับ Web
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        // ไม่ revoke URL ทันทีเพราะจะทำให้ tab ใหม่โหลด PDF ไม่ได้
      } else {
        // สำหรับ mobile/desktop ใช้ Printing.layoutPdf
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'ใบเสนอราคา_${quotation.quotationCode}.pdf',
      );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<Uint8List> generateQuotationPdfBytes(Quotation quotation, {BankAccount? bankAccount, String? signerName}) async {
    try {
      final pdf = await _createQuotationPdf(quotation, bankAccount: bankAccount, signerName: signerName ?? defaultSignerName);
      return pdf.save();
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<pw.Document> _createQuotationPdf(Quotation quotation, {BankAccount? bankAccount, required String signerName}) async {
    final pdf = pw.Document();

    // กำหนดขนาดฟอนต์
    const double fontSizeText = 16.0;
    const double fontSizeCustomer = 14.0;

    // โหลดรูปโลโก้จาก assets
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      final logoBytes = logoData.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      print('ไม่พบรูปโลโก้: $e');
      logoImage = null;
    }

    // โหลดฟอนต์ไทย
    pw.Font? thaiFont;
    try {
        // ลองใช้ฟอนต์ Cordia New จากไฟล์
        final fontData = await rootBundle.load('assets/fonts/CORDIA.ttf');
        thaiFont = pw.Font.ttf(fontData);
    } catch (e) {
      try {
        // ฟอนต์สำรอง 1: Kanit (ฟอนต์หลัก - คล้าย Cordia New)
        thaiFont = await PdfGoogleFonts.notoSansThaiRegular();
      } catch (e2) {
        try {
          // ฟอนต์สำรอง 2: Noto Sans Thai
          thaiFont = await PdfGoogleFonts.kanitRegular();
        } catch (e3) {
          try {
            // ฟอนต์สำรอง 3: Sarabun (ฟอนต์ไทยแบบดั้งเดิม)
            thaiFont = await PdfGoogleFonts.sarabunRegular();
          } catch (e4) {
            try {
              // ฟอนต์สำรอง 4: Open Sans
              thaiFont = await PdfGoogleFonts.openSansRegular();
            } catch (e5) {
              // ใช้ฟอนต์ default
              print('ไม่พบฟอนต์ไทย ใช้ฟอนต์ default: $e5');
              thaiFont = null;
            }
          }
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              _buildCompanyHeader(thaiFont, logoImage),
              pw.SizedBox(height: 5),
              
              // Document Title
              _buildDocumentTitle(thaiFont),
              pw.SizedBox(height: 5),
              
                // Customer and Quotation Info
                _buildCustomerAndQuotationInfo(quotation, thaiFont, fontSizeCustomer),
              pw.SizedBox(height: 5),
              
              // Items Table
              _buildItemsTable(quotation, thaiFont, fontSizeText),
              // pw.SizedBox(height: 5),
              
              // Summary Section
              _buildSummarySection(quotation, thaiFont, fontSizeText),
              pw.SizedBox(height: 5),
            
              
              // Signature Section
              _buildSignatureSection(thaiFont, quotation, fontSizeText, signerName),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildCompanyHeader(pw.Font? thaiFont, pw.MemoryImage? logoImage) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Company Logo
          pw.Container(
            width: 100,
            height: 100,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.white, width: 1),
            ),
            child: pw.Center(
              child: logoImage != null 
                ? pw.Image(
                    logoImage,
                    width: 100,
                    height: 100,
                    fit: pw.BoxFit.contain,
                  )
                : pw.Text(
                    'GPS',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      font: thaiFont,
                    ),
                  ),
            ),
          ),
          pw.SizedBox(width: 15),
          
          // Company Info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'บริษัท กู๊ดแพ็คเกจจิ้งซัพพลาย จำกัด (สำนักงานใหญ่)',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: thaiFont,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '122 หมู่บ้านโชคชัยปัญจทรัพย์ 44 ซอยบรมราชชนนี 111 ถนนบรมราชชนนี',
                  style: pw.TextStyle(fontSize: 16, font: thaiFont),
                ),
                pw.Text(
                  'แขวงศาลาธรรมสพน์ เขตทวีวัฒนา กรุงเทพมหานคร 10170',
                  style: pw.TextStyle(fontSize: 16, font: thaiFont),
                ),
                pw.Text(
                  'เลขประจำตัวผู้เสียภาษี: 0105564123203',
                  style: pw.TextStyle(fontSize: 16, font: thaiFont),
                ),
                pw.Text(
                  'TEL: 0972312000 Email: goodpackagingsupply@hotmail.com',
                  style: pw.TextStyle(fontSize: 16, font: thaiFont),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDocumentTitle(pw.Font? thaiFont) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.black, thickness: 1),
          pw.SizedBox(height: 1),
          pw.Row(
            children: [
              pw.Text(
                'ต้นฉบับ',
                style: pw.TextStyle(
                  fontSize: 16,
                  font: thaiFont,
                ),
              ),
              pw.Spacer(),
              pw.Column(
                children: [
                  pw.Text(
                    'ใบเสนอราคา',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      font: thaiFont,
                    ),
                  ),
                  pw.Text(
                    'Quotation',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      font: thaiFont,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
            ],
          ),
          pw.SizedBox(height: 1),
          pw.Divider(color: PdfColors.black, thickness: 1),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerAndQuotationInfo(Quotation quotation, pw.Font? thaiFont, double fontSizeText) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Customer Info
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 80, // กำหนดความกว้างของ label ให้เท่ากัน
                      child: pw.Text(
                        'ลูกค้า:',
                        style: pw.TextStyle(
                          fontSize: fontSizeText,
                          fontWeight: pw.FontWeight.bold,
                          font: thaiFont,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        quotation.customerName,
                        style: pw.TextStyle(
                          fontSize: fontSizeText,
                          fontWeight: pw.FontWeight.bold,
                          font: thaiFont,
                        ),
                      ),
                    ),
                  ],
                ),
                if (quotation.address != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'ที่อยู่:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          quotation.address!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (quotation.phone != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'โทรศัพท์:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          quotation.phone!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (quotation.contactName != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'ผู้ติดต่อ:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          quotation.contactName!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Quotation Info
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 100, // กำหนดความกว้างของ label ให้เท่ากัน
                      child: pw.Text(
                        'เลขที่:',
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        quotation.quotationCode,
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 100,
                      child: pw.Text(
                        'วันที่:',
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _formatDateThai(quotation.quotationDate),
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                  ],
                ),
                if (quotation.customerCode != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'รหัสลูกค้า:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          quotation.customerCode!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (quotation.taxId != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'เลขประจำตัวผู้เสียภาษี:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          quotation.taxId!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (quotation.validUntil != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'ราคาใช้ได้ถึง:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _formatDateThai(quotation.validUntil!),
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Quotation quotation, pw.Font? thaiFont, double fontSizeText) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.all(2),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'ลำดับ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: fontSizeText,
                      font: thaiFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'รายการ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: fontSizeText,
                      font: thaiFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'จำนวน',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: fontSizeText,
                      font: thaiFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'ราคา/ชิ้น',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: fontSizeText,
                      font: thaiFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'รวมเงิน',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: fontSizeText,
                      font: thaiFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Table Rows
          ...quotation.items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            
            return pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: const pw.BorderSide(color: PdfColors.black),
                  right: const pw.BorderSide(color: PdfColors.black),
                  // bottom: const pw.BorderSide(color: PdfColors.black),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      index.toString(),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.productName,
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _formatQuantity(item.quantity),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _formatCurrency(item.unitPrice),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _formatCurrency(item.totalPrice),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(Quotation quotation, pw.Font? thaiFont, double fontSizeText) {
    final subtotal = quotation.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final vatAmount = quotation.isVAT ? subtotal * 0.07 : 0.0;
    final grandTotal = quotation.calculateGrandTotal();

    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder(
            left: const pw.BorderSide(color: PdfColors.black, width: 1),
            right: const pw.BorderSide(color: PdfColors.black, width: 1),
            top: const pw.BorderSide(color: PdfColors.black, width: 1),
            bottom: const pw.BorderSide(color: PdfColors.black, width: 1),
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(50),  // คอลัมน์ซ้ายสุด (ตัวอักษร)
            1: const pw.FlexColumnWidth(3.5),    // คอลัมน์ธนาคารและยอดเงินตัวอักษร
            2: const pw.FlexColumnWidth(2),  // คอลัมน์รายการ
            3: const pw.FlexColumnWidth(1.5),  // คอลัมน์ยอดเงิน
          },
          children: [
          // แถวที่ 1: ราคาสินค้า
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                child: pw.Text(
                  'ธนาคาร',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              _buildBankInfoCell(quotation, thaiFont, 0, fontSizeText), // แสดงธนาคาร
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                child: pw.Text(
                  'ราคาสินค้า / Value Amount',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(1, 1, 2, 1),
                child: pw.Text(
                  _formatCurrency(subtotal),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          // แถวที่ 2: ภาษี
          pw.TableRow(
            children: [
              pw.Container(), // คอลัมน์ว่าง
              _buildBankInfoCell(quotation, thaiFont, 1, fontSizeText), // แสดงชื่อบริษัท
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                child: pw.Text(
                  'ภาษี / Vat 7 %',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(1, 1, 2, 1),
                child: pw.Text(
                  _formatCurrency(vatAmount),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          // แถวที่ 3: รวมภาษี
          pw.TableRow(
            children: [
              pw.Container(), // คอลัมน์ว่าง
              _buildBankInfoCell(quotation, thaiFont, 2, fontSizeText), // แสดงเลขบัญชี
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                child: pw.Text(
                  'รวมภาษี / Include Vat',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(1, 1, 2, 1),
                child: pw.Text(
                  _formatCurrency(subtotal + vatAmount),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          // แถวที่ 4: ค่าส่ง และ สุทธิ (merge 2 rows)
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                child: pw.Text(
                  'ตัวอักษร',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              _buildMergedAmountInWordsCell(quotation, thaiFont, fontSizeText), // แสดงยอดเงินตัวอักษรแบบ merge
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ค่าส่ง / Shipping Fee',
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                    ),
                    pw.Text(
                      'สุทธิ / Net Amount',
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(1, 1, 2, 1),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _formatCurrency(quotation.shippingCost),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.Text(
                      _formatCurrency(grandTotal),
                      style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        ),
        // Footer สีเขียว
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
          decoration: const pw.BoxDecoration(
            color: PdfColors.lightGreen50,
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.black, width: 1),
              right: pw.BorderSide(color: PdfColors.black, width: 1),
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          child: pw.Text(
            'หมายเหตุ: ${quotation.notes ?? 'หลังโอนยอด จัดส่งภายใน1-3 วันทำการ'}',
            style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
            textAlign: pw.TextAlign.left,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBankInfoCell(Quotation quotation, pw.Font? thaiFont, int rowIndex, double fontSizeText) {
    String bankInfo = '';
    switch (rowIndex) {
      case 0:
        bankInfo = quotation.bankName ?? '';
        break;
      case 1:
        bankInfo =  quotation.bankAccountName ?? '';
        break;
      case 2:
        bankInfo =  quotation.bankAccountNumber ?? '';
        break;
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(1, 1, 1, 1),
      child: pw.Text(
        bankInfo,
        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
      ),
    );
  }


  // Function สำหรับสร้าง cell ที่ merge กับ row ถัดไป
  static pw.Widget _buildMergedAmountInWordsCell(Quotation quotation, pw.Font? thaiFont, double fontSizeText) {
    final grandTotal = quotation.calculateGrandTotal();
    final fullAmountInWords = _convertToThaiText(grandTotal);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(1),
      height: 40, // ความสูงสำหรับ 2 rows
      child: pw.Text(
        fullAmountInWords,
        style: pw.TextStyle(
          fontSize: fontSizeText,
          font: thaiFont,
        ),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget _buildSignatureSection(pw.Font? thaiFont, Quotation quotation, double fontSizeText, String signerName) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          // คอลัมน์ที่ 1 - ว่าง
          pw.Expanded(
            flex: 1,
            child: pw.Container(),
          ),
          
          // คอลัมน์ที่ 2 - ว่าง
          pw.Expanded(
            flex: 1,
            child: pw.Container(),
          ),
          
          // คอลัมน์ที่ 3 - Customer signature
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15), // เว้นบรรทัดให้เซ็นชื่อ
                pw.Container(
                  width: 150,
                  height: 1,
                  // color: PdfColors.black,
                ),
                pw.SizedBox(height: 10), // เว้นหลังบรรทัดลงชื่อ
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้มีอำนาจอนุมัติ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  _formatDateThai(quotation.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        
          // คอลัมน์ที่ 4 - Company signature
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15), // เว้นบรรทัดให้เซ็นชื่อ
                pw.Container(
                  width: 150,
                  height: 1,
                  // color: PdfColors.black,
                ),
                pw.SizedBox(height: 10), // เว้นหลังบรรทัดลงชื่อ
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้เสนอราคา',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  _formatDateThai(quotation.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateThai(DateTime date) {
    final months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final year = (date.year + 543) % 100; // Convert to Buddhist year
    
    return '$day $month $year';
  }


  static String _convertToThaiText(double amount) {
    // Convert to Thai text with proper formatting
    final intPart = amount.floor();
    final decimalPart = ((amount - intPart) * 100).round();
    
    final thaiText = _numberToThaiText(intPart);
    final suffix = decimalPart > 0 ? '${_numberToThaiText(decimalPart)}สตางค์' : 'ถ้วน';
    
    return '$thaiTextบาท$suffix';
  }


  static String _numberToThaiText(int number) {
    if (number == 0) return 'ศูนย์';
    
    final units = ['', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
    final tens = ['', '', 'ยี่', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
    
    if (number < 10) return units[number];
    if (number < 100) {
      final ten = number ~/ 10;
      final unit = number % 10;
      if (ten == 1 && unit == 0) return 'สิบ';
      if (ten == 1) return 'สิบ${units[unit]}';
      if (unit == 0) return '${tens[ten]}สิบ';
      return '${tens[ten]}สิบ${units[unit]}';
    }
    
    // Handle hundreds
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      if (hundred == 1) {
        return remainder == 0 ? 'หนึ่งร้อย' : 'หนึ่งร้อย${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[hundred]}ร้อย' : '${units[hundred]}ร้อย${_numberToThaiText(remainder)}';
      }
    }
    
    // Handle thousands
    if (number < 10000) {
      final thousand = number ~/ 1000;
      final remainder = number % 1000;
      if (thousand == 1) {
        return remainder == 0 ? 'หนึ่งพัน' : 'หนึ่งพัน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[thousand]}พัน' : '${units[thousand]}พัน${_numberToThaiText(remainder)}';
      }
    }
    
    // Handle ten thousands
    if (number < 100000) {
      final tenThousand = number ~/ 10000;
      final remainder = number % 10000;
      if (tenThousand == 1) {
        return remainder == 0 ? 'หนึ่งหมื่น' : 'หนึ่งหมื่น${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[tenThousand]}หมื่น' : '${units[tenThousand]}หมื่น${_numberToThaiText(remainder)}';
      }
    }
    
    // Handle hundred thousands
    if (number < 1000000) {
      final hundredThousand = number ~/ 100000;
      final remainder = number % 100000;
      if (hundredThousand == 1) {
        return remainder == 0 ? 'หนึ่งแสน' : 'หนึ่งแสน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[hundredThousand]}แสน' : '${units[hundredThousand]}แสน${_numberToThaiText(remainder)}';
      }
    }
    
    // Handle millions
    if (number < 10000000) {
      final million = number ~/ 1000000;
      final remainder = number % 1000000;
      if (million == 1) {
        return remainder == 0 ? 'หนึ่งล้าน' : 'หนึ่งล้าน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[million]}ล้าน' : '${units[million]}ล้าน${_numberToThaiText(remainder)}';
      }
    }
    
    // For very large numbers, return simplified version
    return number.toString();
  }

  static String _formatCurrency(double amount) {
    // แปลงเป็น string และแยกส่วนทศนิยม
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // เพิ่ม comma ทุก 3 หลัก
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }
    
    return '$formattedInteger.$decimalPart';
  }

  static String _formatQuantity(int quantity) {
    // เพิ่ม comma ทุก 3 หลัก
    String formattedQuantity = '';
    final quantityString = quantity.toString();
    
    for (int i = 0; i < quantityString.length; i++) {
      if (i > 0 && (quantityString.length - i) % 3 == 0) {
        formattedQuantity += ',';
      }
      formattedQuantity += quantityString[i];
    }
    
    return formattedQuantity;
  }
}
