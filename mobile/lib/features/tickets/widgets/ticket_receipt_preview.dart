import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/receipt_text.dart';
import '../../../domain/models/ticket_issue_draft.dart';
import '../../../domain/models/ticket_receipt_data.dart';

/// On-screen receipt preview matching the printed 58mm layout.
class TicketReceiptPreview extends StatelessWidget {
  const TicketReceiptPreview({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.routeLabel,
    required this.fleetNumber,
    required this.currency,
    required this.amount,
    this.origin,
    this.destination,
    this.passengerPhone,
    this.ticketNumber,
    this.issuedAt,
    this.syncPending = false,
    this.verifyUrl,
  });

  factory TicketReceiptPreview.fromDraft(
    TicketIssueDraft draft, {
    String? ticketNumberOverride,
  }) {
    return TicketReceiptPreview(
      title: 'Ticket preview',
      categoryLabel: draft.modeLabel.toUpperCase(),
      routeLabel: draft.routeLabel,
      origin: draft.departure,
      destination: draft.destination,
      fleetNumber: draft.trip.fleetNumber ?? '-',
      currency: draft.currency,
      amount: draft.isPair
          ? (draft.passengerAmount ?? 0)
          : (draft.amount ?? 0),
      passengerPhone: draft.passengerPhone,
      ticketNumber: ticketNumberOverride ?? 'Pending',
    );
  }

  factory TicketReceiptPreview.fromReceipt(TicketReceiptData receipt) {
    return TicketReceiptPreview(
      title: 'Ticket receipt',
      categoryLabel: receipt.categoryLabel,
      routeLabel: receipt.trip.routeLabel,
      origin: receipt.ticket.departure ?? receipt.trip.routeOrigin,
      destination: receipt.ticket.destination ?? receipt.trip.routeDestination,
      fleetNumber: receipt.trip.fleetNumber ?? '-',
      currency: receipt.ticket.currency,
      amount: receipt.ticket.amount,
      passengerPhone: receipt.ticket.passengerPhone,
      ticketNumber: receipt.ticket.displayNumber,
      issuedAt: receipt.ticket.issuedAt,
      syncPending: receipt.ticket.syncStatus != 'synced',
      verifyUrl: receipt.verifyUrl,
    );
  }

  final String title;
  final String categoryLabel;
  final String routeLabel;
  final String fleetNumber;
  final String currency;
  final double amount;
  final String? origin;
  final String? destination;
  final String? passengerPhone;
  final String? ticketNumber;
  final DateTime? issuedAt;
  final bool syncPending;
  final String? verifyUrl;

  @override
  Widget build(BuildContext context) {
    final issuedLabel = issuedAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(issuedAt!)
        : 'On confirmation';
    final from = origin?.trim().isNotEmpty == true
        ? origin!
        : _splitRoute(routeLabel).$1;
    final to = destination?.trim().isNotEmpty == true
        ? destination!
        : _splitRoute(routeLabel).$2;
    final routeLine = '$from -> $to';

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/brand/cboy-receipt-logo.png',
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'BUS TICKET',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              categoryLabel,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Divider(height: AppSpacing.md),
            Text(
              routeLine,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Ticket', ticketNumber ?? '-'),
            _row(context, 'Bus', fleetNumber),
            if (passengerPhone != null && passengerPhone!.isNotEmpty)
              _row(context, 'Phone', passengerPhone!),
            _row(context, 'Issued', issuedLabel),
            if (syncPending)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'OFFLINE - SYNC PENDING',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (verifyUrl != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: QrImageView(
                  data: verifyUrl!,
                  version: QrVersions.auto,
                  size: 132,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.charcoal,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scan to verify ticket',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'QR code appears after the ticket is issued',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (verifyUrl != null)
              Text(
                Env.publicWebUrl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  (String, String) _splitRoute(String label) {
    final cleaned = sanitizeReceiptText(label);
    final parts = cleaned.split(RegExp(r'\s*->\s*'));
    if (parts.length >= 2) {
      return (parts.first, parts.sublist(1).join(' -> '));
    }
    return (cleaned, '-');
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              sanitizeReceiptText(value),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
