import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to generate and print shipping labels for orders.
/// Designed for standard A6 (10.5 × 14.8 cm) adhesive labels.
class ShippingLabelService {
  // Removed normalization to support full Unicode/Turkish characters.

  /// Generate and print a shipping label for the given order data.
  static Future<void> printLabel(Map<String, dynamic> data, String docId) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();

    final orderId = data['orderId'] ?? docId;
    final customerName = data['customerName']?.toString() ?? '';
    final customerPhone = data['customerPhone'] ?? '';
    final total = (data['total'] ?? 0).toDouble();
    final items = data['items'] as List<dynamic>? ?? [];
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final itemCount = items.fold<int>(0, (acc, item) => acc + ((item['quantity'] ?? 1) as int));

    // Parse date
    String dateStr = '';
    final createdAt = data['createdAt'];
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(createdAt.toDate());
    } else {
      dateStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(DateTime.now());
    }

    // Build address string
    final addrParts = <String>[];
    if (address['fullAddress'] != null) {
      addrParts.add(address['fullAddress'].toString());
    }
    final distCity = [
      if (address['district'] != null) address['district'].toString(),
      if (address['city'] != null) address['city'].toString(),
    ].join(' / ');
    if (distCity.isNotEmpty) addrParts.add(distCity);
    final fullAddress = addrParts.join('\n');

    // Recipient phone
    final phone = address['phone'] ?? customerPhone;
    final recipientName = address['fullName']?.toString() ?? customerName;

    // Build items summary
    final itemsSummary = items.map((item) {
      final name = item['name']?.toString() ?? 'Ürün';
      final qty = item['quantity'] ?? 1;
      final size = item['size']?.toString() ?? '';
      final color = item['color']?.toString() ?? '';
      final detail = [
        if (size.isNotEmpty) size,
        if (color.isNotEmpty) color,
      ].join(' / ');
      return '$name${detail.isNotEmpty ? " ($detail)" : ""} × $qty';
    }).toList();

    // A6 label size (10.5cm × 14.8cm)
    const labelFormat = PdfPageFormat(
      10.5 * PdfPageFormat.cm,
      14.8 * PdfPageFormat.cm,
      marginAll: 0.6 * PdfPageFormat.cm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        build: (pw.Context context) {
          final textStyle = pw.TextStyle(font: font);
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER: Brand + Order ID ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'HUMAN NATURE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        font: boldFont,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.Text(
                      orderId,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        font: boldFont,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // ── Date ──
              pw.Text(
                dateStr,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: font),
              ),
              pw.SizedBox(height: 10),

              // ── GÖNDEREN (Sender) ──
              _buildLabelSection(
                title: 'GÖNDEREN',
                rows: [
                  _LabelRow('', 'HUMAN NATURE', bold: true, font: boldFont),
                  // You can add your store address here
                ],
                font: font,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 8),

              // ── Divider ──
              pw.Container(
                width: double.infinity,
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 8),

              // ── ALICI (Recipient) ──
              _buildLabelSection(
                title: 'ALICI',
                rows: [
                  _LabelRow('Ad Soyad:', recipientName, bold: true, fontSize: 12, font: boldFont),
                  if (phone.isNotEmpty) _LabelRow('Telefon:', phone, font: font),
                  if (fullAddress.isNotEmpty) _LabelRow('Adres:', fullAddress, font: font),
                ],
                font: font,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 10),

              // ── Divider ──
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // ── ÜRÜNLER (Items) ──
              pw.Text(
                'ÜRÜNLER ($itemCount ADET)',
                style: pw.TextStyle(
                  fontSize: 9,
                  font: boldFont,
                  letterSpacing: 1.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              ...itemsSummary.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    '- $item',
                    style: pw.TextStyle(fontSize: 8, font: font),
                    maxLines: 2,
                  ),
                ),
              ),

              pw.Spacer(),

              // ── FOOTER: Total ──
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOPLAM TUTAR',
                    style: pw.TextStyle(
                      fontSize: 10,
                      font: boldFont,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Text(
                    '${total.toStringAsFixed(2)} TL',
                    style: pw.TextStyle(
                      fontSize: 14,
                      font: boldFont,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // ── Barcode (Order ID) ──
              pw.Center(
                child: pw.BarcodeWidget(
                  data: orderId,
                  barcode: pw.Barcode.code128(),
                  width: 180,
                  height: 36,
                  textStyle: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Launch the system print dialog — detects all connected printers
    // (WiFi, USB, Bluetooth, etc.)
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'HUMAN_NATURE_$orderId',
      format: labelFormat,
    );
  }

  /// Helper to build a labeled section.
  static pw.Widget _buildLabelSection({
    required String title,
    required List<_LabelRow> rows,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            font: boldFont,
            letterSpacing: 1.5,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        ...rows.map((row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (row.label.isNotEmpty)
                    pw.SizedBox(
                      width: 60,
                      child: pw.Text(
                        row.label,
                        style: pw.TextStyle(
                          fontSize: row.fontSize ?? 9,
                          color: PdfColors.grey600,
                          font: font,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Text(
                      row.value,
                      style: pw.TextStyle(
                        fontSize: row.fontSize ?? 10,
                        font: row.bold ? boldFont : font,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

/// Simple data class for label row.
class _LabelRow {
  final String label;
  final String value;
  final bool bold;
  final double? fontSize;
  final pw.Font? font;

  const _LabelRow(this.label, this.value, {this.bold = false, this.fontSize, this.font});
}
