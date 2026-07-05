import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../domain/models/ticket_issue_draft.dart';
import '../../../domain/models/ticket_receipt_data.dart';

/// On-screen receipt preview matching the printed layout.
class TicketReceiptPreview extends StatelessWidget {
  const TicketReceiptPreview({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.routeLabel,
    required this.fleetNumber,
    required this.currency,
    required this.amount,
    this.passengerName,
    this.passengerPhone,
    this.ticketNumber,
    this.issuedAt,
    this.syncPending = false,
  });

  factory TicketReceiptPreview.fromDraft(
    TicketIssueDraft draft, {
    String? ticketNumberOverride,
  }) {
    return TicketReceiptPreview(
      title: 'Ticket preview',
      categoryLabel: draft.modeLabel.toUpperCase(),
      routeLabel: draft.routeLabel,
      fleetNumber: draft.trip.fleetNumber ?? '—',
      currency: draft.currency,
      amount: draft.isPair
          ? (draft.passengerAmount ?? 0)
          : (draft.amount ?? 0),
      passengerName: draft.passengerName,
      passengerPhone: draft.passengerPhone,
      ticketNumber: ticketNumberOverride ?? 'Pending',
    );
  }

  factory TicketReceiptPreview.fromReceipt(TicketReceiptData receipt) {
    return TicketReceiptPreview(
      title: 'Ticket receipt',
      categoryLabel: receipt.categoryLabel,
      routeLabel: receipt.trip.routeLabel,
      fleetNumber: receipt.trip.fleetNumber ?? '—',
      currency: receipt.ticket.currency,
      amount: receipt.ticket.amount,
      passengerName: receipt.ticket.passengerName,
      passengerPhone: receipt.ticket.passengerPhone,
      ticketNumber: receipt.ticket.displayNumber,
      issuedAt: receipt.ticket.issuedAt,
      syncPending: receipt.ticket.syncStatus != 'synced',
    );
  }

  final String title;
  final String categoryLabel;
  final String routeLabel;
  final String fleetNumber;
  final String currency;
  final double amount;
  final String? passengerName;
  final String? passengerPhone;
  final String? ticketNumber;
  final DateTime? issuedAt;
  final bool syncPending;

  @override
  Widget build(BuildContext context) {
    final issuedLabel = issuedAt != null
        ? DateFormat('dd MMM yyyy · HH:mm').format(issuedAt!)
        : 'On confirmation';

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'COUNTRYBOY',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.brandRed,
                    letterSpacing: 2,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Ticket', ticketNumber ?? '—', emphasize: true),
            _row(context, 'Type', categoryLabel),
            _row(context, 'Route', routeLabel),
            _row(context, 'Bus', fleetNumber),
            if (passengerName != null && passengerName!.isNotEmpty) ...[
              _row(context, 'Passenger', passengerName!),
              if (passengerPhone != null) _row(context, 'Phone', passengerPhone!),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Issued', issuedLabel),
            if (syncPending)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Will be saved locally if offline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
