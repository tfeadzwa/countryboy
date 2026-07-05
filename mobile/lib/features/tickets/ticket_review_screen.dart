import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../features/home/home_screen.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/issue_flow_step_header.dart';
import 'widgets/ticket_receipt_preview.dart';

class TicketReviewScreen extends ConsumerStatefulWidget {
  const TicketReviewScreen({super.key, required this.draft});

  final TicketIssueDraft draft;

  @override
  ConsumerState<TicketReviewScreen> createState() => _TicketReviewScreenState();
}

class _TicketReviewScreenState extends ConsumerState<TicketReviewScreen> {
  bool _issuing = false;
  String? _error;

  Future<void> _confirmAndIssue() async {
    if (_issuing) return;

    setState(() {
      _issuing = true;
      _error = null;
    });

    final draft = widget.draft;
    final idempotencyKey = const Uuid().v4();

    try {
      late TicketIssueResult result;

      if (draft.isPair) {
        final pair = await ref.read(ticketRepositoryProvider).issuePassengerLuggagePair(
              tripId: draft.trip.id,
              currency: draft.currency,
              passengerAmount: draft.passengerAmount!,
              luggageAmount: draft.luggageAmount!,
              passengerName: draft.passengerName!,
              passengerPhone: draft.passengerPhone!,
              departure: draft.trip.routeOrigin,
              destination: draft.trip.routeDestination,
              idempotencyKey: idempotencyKey,
            );
        result = TicketIssueResult(trip: draft.trip, pair: pair);
      } else {
        final ticket = await ref.read(ticketRepositoryProvider).issueTicket(
              tripId: draft.trip.id,
              ticketCategory: draft.mode,
              currency: draft.currency,
              amount: draft.amount!,
              departure: draft.trip.routeOrigin,
              destination: draft.trip.routeDestination,
              idempotencyKey: idempotencyKey,
              passengerName: draft.passengerName,
              passengerPhone: draft.passengerPhone,
            );
        result = TicketIssueResult(trip: draft.trip, single: ticket);
      }

      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      context.pushReplacement('/tickets/issue/print', extra: result);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Ticket'),
        leading: BackButton(onPressed: _issuing ? null : () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const IssueFlowStepHeader(
              step: 2,
              total: 3,
              label: 'Confirm details',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Check the ticket details before issuing.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (draft.isPair) ...[
              TicketReceiptPreview.fromDraft(
                draft,
                ticketNumberOverride: 'Passenger ticket',
              ),
              const SizedBox(height: AppSpacing.md),
              TicketReceiptPreview(
                title: 'Luggage ticket preview',
                categoryLabel: 'LUGGAGE',
                routeLabel: draft.routeLabel,
                fleetNumber: draft.trip.fleetNumber ?? '—',
                currency: draft.currency,
                amount: draft.luggageAmount ?? 0,
                passengerName: draft.passengerName,
                passengerPhone: draft.passengerPhone,
                ticketNumber: 'Luggage ticket',
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${draft.currency} ${draft.totalAmount!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.brandRed,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              TicketReceiptPreview.fromDraft(draft),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: draft.isPair ? 'Confirm & issue 2 tickets' : 'Confirm & issue',
              loading: _issuing,
              onPressed: _confirmAndIssue,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Edit details',
              outlined: true,
              onPressed: _issuing ? null : () => context.pop(),
              icon: Icons.edit_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
