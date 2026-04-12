import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/deal.dart';

class ReceiptService {
  static const _green = PdfColor.fromInt(0xFF2E9D5B);
  static const _blue = PdfColor.fromInt(0xFF3182CE);
  static const _dark = PdfColor.fromInt(0xFF1A1A1A);
  static const _grey = PdfColor.fromInt(0xFF718096);

  static Future<void> generateAndShowReceipt(Deal deal, {required String activeRole}) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/mpesacrowlogo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('MMM dd, yyyy HH:mm');

    final isBuyer = activeRole == 'buyer';
    final roleColor = isBuyer ? _green : _blue;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, height: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('OFFICIAL RECEIPT',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: roleColor)),
                      pw.Text('Transaction ID: ${deal.transactionId}',
                          style: pw.TextStyle(fontSize: 10, color: _grey)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Status Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _green.shade(0.2)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('✓ COMPLETED',
                        style: pw.TextStyle(
                            color: _green, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 8),
                    pw.Text('Funds successfully released to seller.',
                        style: const pw.TextStyle(fontSize: 10, color: _grey)),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Deal Info
              pw.Text('Deal Description',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold, color: _grey)),
              pw.SizedBox(height: 8),
              pw.Text(deal.description,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold, color: _dark)),

              pw.SizedBox(height: 30),

              // Financial Details
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Item Amount', 'KSh ${fmt.format(deal.amount)}'),
                    _buildRow('Escrow Fee', 'KSh ${fmt.format((deal.amount * 0.015).ceil())}'),
                    pw.Divider(color: PdfColors.grey200),
                    _buildRow('Total Value', 'KSh ${fmt.format((deal.amount * 1.015).ceil())}',
                        isBold: true),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Participant Details
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Buyer Phone',
                            style: pw.TextStyle(fontSize: 10, color: _grey)),
                        pw.Text('+${deal.buyerPhone ?? "Unspecified"}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Seller Phone',
                            style: pw.TextStyle(fontSize: 10, color: _grey)),
                        pw.Text('+${deal.sellerPhone}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Timeline Info
              pw.Text('Timeline Confirmation',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold, color: _grey)),
              pw.SizedBox(height: 8),
              _buildTimelineRow('Created At', deal.createdAt),
              if (deal.paymentConfirmedAt != null)
                _buildTimelineRow('Payment Confirmed', deal.paymentConfirmedAt!),
              if (deal.approvedAt != null)
                _buildTimelineRow('Funds Released', deal.approvedAt!),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey200),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PesaCrow Escrow Service',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Safeguarding your transactions.',
                          style: const pw.TextStyle(fontSize: 8, color: _grey)),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'https://pesacrow.top/verify/${deal.transactionId}',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PesaCrow_Receipt_${deal.transactionId}.pdf',
    );
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildTimelineRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(width: 6, height: 6, color: _grey),
          pw.SizedBox(width: 8),
          pw.Text('$label:', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
