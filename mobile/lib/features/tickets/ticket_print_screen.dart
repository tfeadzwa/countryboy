import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../domain/models/ticket_receipt_data.dart';
import '../../features/home/home_screen.dart';
import '../../services/ticket_receipt_builder.dart';
import '../../services/ticket_print_service.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/issue_flow_step_header.dart';
import 'widgets/ticket_receipt_preview.dart';

class TicketPrintScreen extends ConsumerStatefulWidget {
  const TicketPrintScreen({super.key, required this.result});

  final TicketIssueResult result;

  @override
  ConsumerState<TicketPrintScreen> createState() => _TicketPrintScreenState();
}

class _TicketPrintScreenState extends ConsumerState<TicketPrintScreen> {
  List<TicketReceiptData>? _receipts;
  bool _loading = true;
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      final receipts = await buildReceiptData(ref, widget.result);
      setState(() => _receipts = receipts);
    } catch (e) {
      setState(() => _error = 'Could not load receipt details.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _printAll() async {
    final receipts = _receipts;
    if (receipts == null || receipts.isEmpty || _printing) return;

    setState(() {
      _printing = true;
      _error = null;
    });

    try {
      await ref.read(ticketPrintServiceProvider).printReceipts(receipts);
    } catch (e) {
      setState(() => _error = 'Print failed. Try again or use system share.');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _printOne(TicketReceiptData receipt) async {
    if (_printing) return;

    setState(() {
      _printing = true;
      _error = null;
    });

    try {
      await ref.read(ticketPrintServiceProvider).printReceipt(receipt);
    } catch (e) {
      setState(() => _error = 'Print failed. Try again.');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.result.tickets;
    final isPair = tickets.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Ticket'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const IssueFlowStepHeader(
                    step: 3,
                    total: 3,
                    label: 'Print receipt',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Icon(
                    Icons.check_circle,
                    size: 56,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isPair ? 'Tickets issued' : 'Ticket issued',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_receipts != null)
                    ..._receipts!.map((receipt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TicketReceiptPreview.fromReceipt(receipt),
                            if (isPair) ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppButton(
                                label: 'Print ${receipt.categoryLabel}',
                                outlined: true,
                                loading: _printing,
                                onPressed: () => _printOne(receipt),
                                icon: Icons.print_outlined,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppButton(
                    label: isPair ? 'Print all tickets' : 'Print ticket',
                    loading: _printing,
                    onPressed: _printAll,
                    icon: Icons.print,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Issue another ticket',
                    outlined: true,
                    onPressed: () => context.go('/tickets/issue'),
                    icon: Icons.add,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Done',
                    outlined: true,
                    onPressed: () {
                      ref.invalidate(homeDashboardProvider);
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
