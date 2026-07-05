import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/config/env.dart';
import '../domain/models/ticket_receipt_data.dart';

final ticketPrintServiceProvider = Provider<TicketPrintService>(
  (_) => TicketPrintService(),
);

class TicketPrintService {
  /// 58mm thermal roll width (common POS size).
  static const _pageFormat = PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 4 * PdfPageFormat.mm,
  );

  Future<void> printReceipt(TicketReceiptData receipt) async {
    final bytes = await buildReceiptPdf(receipt);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      format: _pageFormat,
      name: 'ticket-${receipt.ticket.displayNumber}',
    );
  }

  Future<void> printReceipts(List<TicketReceiptData> receipts) async {
    for (var i = 0; i < receipts.length; i++) {
      await printReceipt(receipts[i]);
      if (i < receipts.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<Uint8List> buildReceiptPdf(TicketReceiptData receipt) async {
    final doc = pw.Document();
    final issued = DateFormat('dd MMM yyyy · HH:mm').format(receipt.ticket.issuedAt);

    doc.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                'COUNTRYBOY',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Bus Ticket',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            _line('Ticket', receipt.ticket.displayNumber, bold: true),
            _line('Type', receipt.categoryLabel),
            _line('Route', receipt.trip.routeLabel),
            _line('Bus', receipt.trip.fleetNumber ?? '—'),
            if (receipt.ticket.passengerName != null &&
                receipt.ticket.passengerName!.isNotEmpty) ...[
              _line('Passenger', receipt.ticket.passengerName!),
              if (receipt.ticket.passengerPhone != null)
                _line('Phone', receipt.ticket.passengerPhone!),
            ],
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                '${receipt.ticket.currency} ${receipt.ticket.amount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),
            _line('Issued', issued),
            _line('Depot', receipt.depotName),
            _line('Merchant', receipt.merchantCode),
            _line('Conductor', '${receipt.agentName} (${receipt.agentCode})'),
            if (receipt.deviceSerial != null)
              _line('Device', receipt.deviceSerial!),
            if (receipt.ticket.syncStatus != 'synced')
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Center(
                  child: pw.Text(
                    'OFFLINE — SYNC PENDING',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for travelling with us',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                Env.appName,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _line(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
