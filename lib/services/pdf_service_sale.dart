import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../models/sale.dart';
import '../models/bank_account.dart';

enum SaleDocumentType {
  taxInvoice('ใบกำกับภาษี', 'Tax Invoice'),
  receipt('ใบเสร็จรับเงิน', 'Receipt'),
  taxInvoiceReceipt('ใบกำกับภาษี/ใบเสร็จรับเงิน', 'Tax Invoice/Receipt'),
  quotation('ใบเสนอราคา', 'Quotation');

  const SaleDocumentType(this.thaiTitle, this.englishTitle);
  final String thaiTitle;
  final String englishTitle;
}

class PdfServiceSale {
  static const String defaultSignerName = 'สุภาวดี บูรณะโอสถ';
  
  static Future<void> generateAndPrintSale(Sale sale, SaleDocumentType documentType, {BankAccount? bankAccount, String? signerName}) async {
    try {
      // สร้าง PDF document
      final pdf = await _createSalePdf(sale, documentType, bankAccount: bankAccount, signerName: signerName ?? defaultSignerName);
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
        name: '${documentType.thaiTitle}_${sale.saleCode}.pdf',
      );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<Uint8List> generateSalePdfBytes(Sale sale, SaleDocumentType documentType, {BankAccount? bankAccount, String? signerName}) async {
    try {
      final pdf = await _createSalePdf(sale, documentType, bankAccount: bankAccount, signerName: signerName ?? defaultSignerName);
      return pdf.save();
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการสร้าง PDF: $e');
    }
  }

  static Future<pw.Document> _createSalePdf(Sale sale, SaleDocumentType documentType, {BankAccount? bankAccount, required String signerName}) async {
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
              // Company Header (only show for VAT sales)
              if (sale.isVAT) ...[
              _buildCompanyHeader(thaiFont, logoImage),
              pw.SizedBox(height: 5),
              ],
              
              // Document Title
              _buildDocumentTitle(thaiFont, documentType),
              pw.SizedBox(height: 5),
              
              // Customer and Sale Info
              _buildCustomerAndSaleInfo(sale, thaiFont, fontSizeCustomer),
              pw.SizedBox(height: 5),
              
              // Items Table
              _buildItemsTable(sale, thaiFont, fontSizeText),
              
              // Summary Section
              _buildSummarySection(sale, thaiFont, fontSizeText, documentType, bankAccount: bankAccount),
              pw.SizedBox(height: 5),
            
              // Signature Section
              _buildSignatureSection(thaiFont, sale, fontSizeText, documentType, signerName),
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

  static pw.Widget _buildDocumentTitle(pw.Font? thaiFont, SaleDocumentType documentType) {
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
                    documentType.thaiTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      font: thaiFont,
                    ),
                  ),
                  pw.Text(
                    documentType.englishTitle,
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

  static pw.Widget _buildCustomerAndSaleInfo(Sale sale, pw.Font? thaiFont, double fontSizeText) {
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
                      width: 80,
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
                        sale.customerName,
                        style: pw.TextStyle(
                          fontSize: fontSizeText,
                          fontWeight: pw.FontWeight.bold,
                          font: thaiFont,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sale.address != null) ...[
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
                          sale.address!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (sale.phone != null) ...[
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
                          sale.phone!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (sale.contactName != null) ...[
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
                          sale.contactName!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Sale Info
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 100,
                      child: pw.Text(
                        'เลขที่:',
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        sale.saleCode,
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
                        _formatDateThai(sale.saleDate),
                        style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                      ),
                    ),
                  ],
                ),
                if (sale.customerCode != null) ...[
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
                          sale.customerCode!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (sale.taxId != null) ...[
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
                          sale.taxId!,
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                    ],
                  ),
                ],
                if (sale.quotationCode != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'รหัส Quotation:',
                          style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          sale.quotationCode!,
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

  static pw.Widget _buildItemsTable(Sale sale, pw.Font? thaiFont, double fontSizeText) {
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
          ...sale.items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            
            return pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: const pw.BorderSide(color: PdfColors.black),
                  right: const pw.BorderSide(color: PdfColors.black),
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

  static pw.Widget _buildSummarySection(Sale sale, pw.Font? thaiFont, double fontSizeText, SaleDocumentType documentType, {BankAccount? bankAccount}) {
    final itemsTotal = sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    // Calculate VAT based on vatType
    double subtotal = itemsTotal;
    double vatAmount = 0.0;
    double grandTotal = itemsTotal + sale.shippingCost;
    
    if (sale.isVAT) {
      if (sale.vatType == 'inclusive') {
        // VAT ใน: ราคาที่กรอกรวม VAT แล้ว
        subtotal = itemsTotal / 1.07;
        vatAmount = itemsTotal - subtotal;
        grandTotal = itemsTotal + sale.shippingCost;
      } else {
        // VAT นอก: ราคา + VAT 7%
        subtotal = itemsTotal;
        vatAmount = itemsTotal * 0.07;
        grandTotal = itemsTotal + vatAmount + sale.shippingCost;
      }
    }

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
            0: const pw.FixedColumnWidth(50),
            1: const pw.FlexColumnWidth(3.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
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
              _buildBankInfoCell(sale, thaiFont, 0, fontSizeText, bankAccount: bankAccount),
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
          // แถวที่ 2: ภาษี (แสดงเฉพาะเมื่อเป็น VAT)
          if (sale.isVAT) pw.TableRow(
            children: [
              pw.Container(),
              _buildBankInfoCell(sale, thaiFont, 1, fontSizeText, bankAccount: bankAccount),
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
          // แถวที่ 3: รวมภาษี (แสดงเฉพาะเมื่อเป็น VAT)
          if (sale.isVAT) pw.TableRow(
            children: [
              pw.Container(),
              _buildBankInfoCell(sale, thaiFont, 2, fontSizeText, bankAccount: bankAccount),
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
          // แถวที่ 4: ค่าส่ง และ สุทธิ
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(3, 1, 1, 1),
                child: pw.Text(
                  'ตัวอักษร',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ),
              _buildMergedAmountInWordsCell(sale, thaiFont, fontSizeText),
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
                      _formatCurrency(sale.shippingCost),
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
        // Footer
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
            'หมายเหตุ: ${sale.notes ?? 'หลังโอนยอด จัดส่งภายใน1-3 วันทำการ'}',
            style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
            textAlign: pw.TextAlign.left,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBankInfoCell(Sale sale, pw.Font? thaiFont, int rowIndex, double fontSizeText, {BankAccount? bankAccount}) {
    String bankInfo = '';
    switch (rowIndex) {
      case 0:
        // บรรทัดที่ 1: ชื่อธนาคาร
        bankInfo = sale.payment.ourAccountInfo?.bankName ?? bankAccount?.bankName ?? sale.bankName ?? '';
        break;
      case 1:
        // บรรทัดที่ 2: ชื่อบัญชี
        bankInfo = sale.payment.ourAccountInfo?.bankAccountName ?? bankAccount?.bankAccountName ?? sale.bankAccountName ?? '';
        break;
      case 2:
        // บรรทัดที่ 3: หมายเลขบัญชี
        bankInfo = sale.payment.ourAccountInfo?.accountNumber ?? bankAccount?.accountNumber ?? sale.bankAccountNumber ?? '';
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

  static pw.Widget _buildMergedAmountInWordsCell(Sale sale, pw.Font? thaiFont, double fontSizeText) {
    final itemsTotal = sale.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    // Calculate VAT based on vatType
    double vatAmount = 0.0;
    double grandTotal = itemsTotal + sale.shippingCost;
    
    if (sale.isVAT) {
      if (sale.vatType == 'inclusive') {
        // VAT ใน: ราคาที่กรอกรวม VAT แล้ว
        grandTotal = itemsTotal + sale.shippingCost;
      } else {
        // VAT นอก: ราคา + VAT 7%
        vatAmount = itemsTotal * 0.07;
        grandTotal = itemsTotal + vatAmount + sale.shippingCost;
      }
    }
    final fullAmountInWords = _convertToThaiText(grandTotal);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(1),
      height: 40,
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

  static pw.Widget _buildSignatureSection(pw.Font? thaiFont, Sale sale, double fontSizeText, SaleDocumentType documentType, String signerName) {
    switch (documentType) {
      case SaleDocumentType.quotation:
        return _buildQuotationSignatureSection(thaiFont, sale, fontSizeText, signerName);
      case SaleDocumentType.receipt:
        return _buildReceiptSignatureSection(thaiFont, sale, fontSizeText, signerName);
      case SaleDocumentType.taxInvoiceReceipt:
        return _buildTaxInvoiceReceiptSignatureSection(thaiFont, sale, fontSizeText, signerName);
      case SaleDocumentType.taxInvoice:
        return _buildTaxInvoiceSignatureSection(thaiFont, sale, fontSizeText, signerName);
    }
  }

  // 1. Quotation (ปัจจุบัน)
  static pw.Widget _buildQuotationSignatureSection(pw.Font? thaiFont, Sale sale, double fontSizeText, String signerName) {
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
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
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
                  _formatDateThai(sale.updatedAt),
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
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
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
                  _formatDateThai(sale.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. ใบเสร็จรับเงิน - เหลือ column 4 อันเดียว
  static pw.Widget _buildReceiptSignatureSection(pw.Font? thaiFont, Sale sale, double fontSizeText, String signerName) {
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
          
          // คอลัมน์ที่ 3 - ว่าง
          pw.Expanded(
            flex: 1,
            child: pw.Container(),
          ),
          
          // คอลัมน์ที่ 4 - ผู้รับเงิน
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้รับเงิน',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  sale.payment.paymentDate != null 
                    ? _formatDateThai(sale.payment.paymentDate!)
                    : _formatDateThai(sale.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. ใบกำกับภาษี/ใบเสร็จรับเงิน - 4 columns
  static pw.Widget _buildTaxInvoiceReceiptSignatureSection(pw.Font? thaiFont, Sale sale, double fontSizeText, String signerName) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          // คอลัมน์ที่ 1 - ผู้รับสินค้า (ไม่ต้องใส่ชื่อ ไม่ต้องใส่วันที่)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้รับสินค้า',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
              ],
            ),
          ),
        
          // คอลัมน์ที่ 2 - ผู้ส่งสินค้า (สุภาวดี บูรณะโอสถ ไม่ต้องใส่วันที่)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้ส่งสินค้า',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
              ],
            ),
          ),
      
          // คอลัมน์ที่ 3 - ผู้มีอำนาจอนุมัติ (สุภาวดี บูรณะโอสถ sale.updatedAt)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
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
                  _formatDateThai(sale.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        
          // คอลัมน์ที่ 4 - ผู้รับเงิน (สุภาวดี บูรณะโอสถ sale.payment.paymentDate)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้รับเงิน',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  sale.payment.paymentDate != null 
                    ? _formatDateThai(sale.payment.paymentDate!)
                    : _formatDateThai(sale.updatedAt),
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. ใบกำกับภาษี - 3 columns (column 1 ว่าง)
  static pw.Widget _buildTaxInvoiceSignatureSection(pw.Font? thaiFont, Sale sale, double fontSizeText, String signerName) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          // คอลัมน์ที่ 1 - ว่าง
          pw.Expanded(
            flex: 1,
            child: pw.Container(),
          ),
          
          // คอลัมน์ที่ 2 - ผู้รับสินค้า (ไม่ต้องใส่ชื่อ ไม่ต้องใส่วันที่)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้รับสินค้า',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
              ],
            ),
          ),
      
          // คอลัมน์ที่ 3 - ผู้ส่งสินค้า (สุภาวดี บูรณะโอสถ ไม่ต้องใส่วันที่)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  signerName,
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ผู้ส่งสินค้า',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '-',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont, color: PdfColors.white),
                ),
              ],
            ),
          ),
      
          // คอลัมน์ที่ 4 - ผู้มีอำนาจอนุมัติ (สุภาวดี บูรณะโอสถ sale.updatedAt)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลงชื่อ',
                  style: pw.TextStyle(fontSize: fontSizeText, font: thaiFont),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 150,
                  height: 1,
                ),
                pw.SizedBox(height: 10),
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
                  _formatDateThai(sale.updatedAt),
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
    final year = (date.year + 543) % 100;
    
    return '$day $month $year';
  }

  static String _convertToThaiText(double amount) {
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
    
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      if (hundred == 1) {
        return remainder == 0 ? 'หนึ่งร้อย' : 'หนึ่งร้อย${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[hundred]}ร้อย' : '${units[hundred]}ร้อย${_numberToThaiText(remainder)}';
      }
    }
    
    if (number < 10000) {
      final thousand = number ~/ 1000;
      final remainder = number % 1000;
      if (thousand == 1) {
        return remainder == 0 ? 'หนึ่งพัน' : 'หนึ่งพัน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[thousand]}พัน' : '${units[thousand]}พัน${_numberToThaiText(remainder)}';
      }
    }
    
    if (number < 100000) {
      final tenThousand = number ~/ 10000;
      final remainder = number % 10000;
      if (tenThousand == 1) {
        return remainder == 0 ? 'หนึ่งหมื่น' : 'หนึ่งหมื่น${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[tenThousand]}หมื่น' : '${units[tenThousand]}หมื่น${_numberToThaiText(remainder)}';
      }
    }
    
    if (number < 1000000) {
      final hundredThousand = number ~/ 100000;
      final remainder = number % 100000;
      if (hundredThousand == 1) {
        return remainder == 0 ? 'หนึ่งแสน' : 'หนึ่งแสน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[hundredThousand]}แสน' : '${units[hundredThousand]}แสน${_numberToThaiText(remainder)}';
      }
    }
    
    if (number < 10000000) {
      final million = number ~/ 1000000;
      final remainder = number % 1000000;
      if (million == 1) {
        return remainder == 0 ? 'หนึ่งล้าน' : 'หนึ่งล้าน${_numberToThaiText(remainder)}';
      } else {
        return remainder == 0 ? '${units[million]}ล้าน' : '${units[million]}ล้าน${_numberToThaiText(remainder)}';
      }
    }
    
    return number.toString();
  }

  static String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
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
