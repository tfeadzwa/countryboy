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
      final ticket = await ref.read(ticketRepositoryProvider).issueTicket(
            tripId: draft.trip.id,
            ticketCategory: draft.mode,
            currency: draft.currency,
            amount: draft.amount!,
            departure: draft.departure ?? draft.trip.routeOrigin,
            destination: draft.destination ?? draft.trip.routeDestination,
            idempotencyKey: idempotencyKey,
            luggageAmount: draft.luggageAmount,
            luggageDescription: draft.luggageDescription,
          );
      final result = TicketIssueResult(trip: draft.trip, single: ticket);

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
              label: 'Confirm & issue',
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
