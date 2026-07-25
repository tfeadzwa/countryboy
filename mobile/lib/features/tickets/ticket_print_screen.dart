import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../domain/models/ticket_receipt_data.dart';
import '../../features/home/home_screen.dart';
import '../../services/ticket_print_service.dart';
import '../../services/ticket_receipt_builder.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/issue_flow_step_header.dart';
import 'widgets/printer_picker_sheet.dart';
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
  late bool _printed;
  bool _connecting = false;
  bool _issuingSimilar = false;
  String? _error;
  String? _printerLabel;
  bool _printerConnected = false;

  @override
  void initState() {
    super.initState();
    _printed = widget.result.tickets.isNotEmpty &&
        widget.result.tickets.every((t) => t.printed);
    _loadReceipts();
    _restorePrinter();
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

  Future<void> _restorePrinter() async {
    final service = ref.read(ticketPrintServiceProvider);
    final saved = await service.getSavedPrinter();
    if (saved == null) {
      if (mounted) {
        setState(() {
          _printerLabel = null;
          _printerConnected = false;
        });
      }
      return;
    }

    setState(() {
      _connecting = true;
      _printerLabel = saved.name;
    });

    try {
      final ok = await service.connectSaved();
      if (!mounted) return;
      setState(() {
        _printerConnected = ok;
        _printerLabel = saved.name;
        if (!ok) {
          _error =
              'Could not reconnect to ${saved.name}. Tap to choose a printer.';
        }
      });
    } on PrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _printerConnected = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _printerConnected = false);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<bool> _ensurePrinter() async {
    final service = ref.read(ticketPrintServiceProvider);
    if (await service.isConnected()) {
      setState(() => _printerConnected = true);
      return true;
    }

    final connected = await service.connectSaved();
    if (connected) {
      final saved = await service.getSavedPrinter();
      if (!mounted) return false;
      setState(() {
        _printerConnected = true;
        _printerLabel = saved?.name;
      });
      return true;
    }

    if (!mounted) return false;
    final selected = await showPrinterPickerSheet(context, ref);
    if (selected == null) return false;

    setState(() {
      _printerConnected = true;
      _printerLabel =
          selected.name.isEmpty ? 'Printer' : selected.name;
    });
    return true;
  }

  Future<void> _changePrinter() async {
    setState(() {
      _error = null;
      _connecting = true;
    });
    try {
      final selected = await showPrinterPickerSheet(context, ref);
      if (!mounted) return;
      if (selected != null) {
        setState(() {
          _printerConnected = true;
          _printerLabel =
              selected.name.isEmpty ? 'Printer' : selected.name;
        });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _printAll() async {
    final receipts = _receipts;
    if (receipts == null || receipts.isEmpty || _printing || _printed) return;

    setState(() {
      _printing = true;
      _error = null;
    });

    try {
      if (!await _ensurePrinter()) return;
      await ref.read(ticketPrintServiceProvider).printReceipts(receipts);
      if (!mounted) return;
      final ticketIds = widget.result.tickets.map((t) => t.id).toList();
      try {
        await ref.read(ticketRepositoryProvider).markTicketsPrinted(ticketIds);
      } catch (_) {
        // Print succeeded — local mark is best-effort; list will refresh on sync.
      }
      if (!mounted) return;
      setState(() => _printed = true);
    } on PrinterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Print failed. Check the printer and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _sameRouteAgain() async {
    final draft = widget.result.draft;
    if (!widget.result.canRepeatSameRoute ||
        draft == null ||
        _issuingSimilar ||
        _printing) {
      return;
    }

    final amount = draft.amount!;
    final amountLabel = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Same route again?'),
        content: Text(
          'Issue another ${draft.departure} → ${draft.destination} · '
          '${draft.currency} $amountLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _issuingSimilar = true;
      _error = null;
    });

    try {
      final ticket = await ref.read(ticketRepositoryProvider).issueTicket(
            tripId: draft.trip.id,
            ticketCategory: draft.mode,
            currency: draft.currency,
            amount: amount,
            departure: draft.departure!,
            destination: draft.destination!,
            idempotencyKey: const Uuid().v4(),
          );
      final result = TicketIssueResult(
        trip: draft.trip,
        single: ticket,
        draft: draft,
      );

      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      context.pushReplacement('/tickets/issue/print', extra: result);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not issue ticket. Try again.');
      }
    } finally {
      if (mounted) setState(() => _issuingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.result.tickets;
    final isPair = tickets.length > 1;
    final canRepeat = widget.result.canRepeatSameRoute;
    final busy = _printing || _issuingSimilar;

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
                  const SizedBox(height: AppSpacing.md),
                  _PrinterStatusTile(
                    label: _printerLabel,
                    connected: _printerConnected,
                    connecting: _connecting,
                    onTap: (_printing || _printed || _issuingSimilar)
                        ? null
                        : _changePrinter,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_receipts != null)
                    ..._receipts!.map((receipt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TicketReceiptPreview.fromReceipt(receipt),
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
                  AnimatedOpacity(
                    opacity: _printed ? 0.45 : 1,
                    duration: const Duration(milliseconds: 280),
                    child: AppButton(
                      label: _printed
                          ? (isPair ? 'Tickets printed' : 'Ticket printed')
                          : (isPair ? 'Print all tickets' : 'Print ticket'),
                      loading: _printing,
                      onPressed: (_printed || _issuingSimilar) ? null : _printAll,
                      icon: _printed ? Icons.check_circle_outline : Icons.print,
                    ),
                  ),
                  if (canRepeat) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Same route again',
                      loading: _issuingSimilar,
                      onPressed: busy ? null : _sameRouteAgain,
                      icon: Icons.repeat,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Issue another ticket',
                    outlined: true,
                    onPressed:
                        _issuingSimilar ? null : () => context.go('/tickets/issue'),
                    icon: Icons.add,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Done',
                    outlined: true,
                    onPressed: _issuingSimilar
                        ? null
                        : () {
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

class _PrinterStatusTile extends StatelessWidget {
  const _PrinterStatusTile({
    required this.label,
    required this.connected,
    required this.connecting,
    required this.onTap,
  });

  final String? label;
  final bool connected;
  final bool connecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = connecting
        ? 'Connecting…'
        : connected
            ? (label ?? 'Printer connected')
            : (label == null ? 'No printer selected' : 'Not connected · $label');
    final color = connected ? AppColors.success : AppColors.textSecondary;

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              if (connecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_searching,
                  color: color,
                  size: 22,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Text(
                connected ? 'Change' : 'Select',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.brandRed,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
