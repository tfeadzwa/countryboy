import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/issue_flow_step_header.dart';

/// UI issue modes mapped to backend `ticket_category` values.
enum IssueTicketMode {
  passenger('PASSENGER', 'Passenger'),
  combined('PASSENGER_WITH_LUGGAGE', 'Passenger + luggage (1 ticket)'),
  pair('PAIR', 'Passenger + luggage (2 linked tickets)'),
  luggage('LUGGAGE', 'Luggage only');

  const IssueTicketMode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class IssueTicketFormScreen extends ConsumerStatefulWidget {
  const IssueTicketFormScreen({super.key});

  @override
  ConsumerState<IssueTicketFormScreen> createState() =>
      _IssueTicketFormScreenState();
}

class _IssueTicketFormScreenState extends ConsumerState<IssueTicketFormScreen> {
  TripModel? _trip;
  IssueTicketMode _mode = IssueTicketMode.passenger;
  String _currency = 'USD';
  final _amountController = TextEditingController();
  final _passengerAmountController = TextEditingController();
  final _luggageAmountController = TextEditingController();
  final _passengerNameController = TextEditingController();
  final _passengerPhoneController = TextEditingController();
  bool _loading = true;
  String? _error;

  static const _currencies = ['USD', 'ZWL'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _passengerAmountController.dispose();
    _luggageAmountController.dispose();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (trip == null) {
        setState(() => _error = 'No active trip. Start a trip first.');
        return;
      }
      setState(() => _trip = trip);
    } finally {
      setState(() => _loading = false);
    }
  }

  double? _parseAmount(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  ({String name, String phone}) _readPassengerDetails() {
    final name = _passengerNameController.text.trim();
    final phone = _passengerPhoneController.text.trim();

    if (name.length < 2) {
      throw ApiError(message: 'Enter the passenger name (at least 2 characters).');
    }
    if (phone.length < 7) {
      throw ApiError(message: 'Enter a valid passenger phone number.');
    }
    if (!RegExp(r'^[+]?[\d\s()-]+$').hasMatch(phone)) {
      throw ApiError(message: 'Phone number contains invalid characters.');
    }

    return (name: name, phone: phone);
  }

  void _continueToReview() {
    if (_trip == null) return;

    setState(() => _error = null);

    try {
      TicketIssueDraft draft;

      if (_mode == IssueTicketMode.pair) {
        final passengerAmount = _parseAmount(_passengerAmountController.text);
        final luggageAmount = _parseAmount(_luggageAmountController.text);
        if (passengerAmount == null || luggageAmount == null) {
          throw ApiError(message: 'Enter valid passenger and luggage fares.');
        }
        final passengerDetails = _readPassengerDetails();

        draft = TicketIssueDraft(
          trip: _trip!,
          mode: _mode.apiValue,
          currency: _currency,
          passengerAmount: passengerAmount,
          luggageAmount: luggageAmount,
          passengerName: passengerDetails.name,
          passengerPhone: passengerDetails.phone,
        );
      } else {
        final amount = _parseAmount(_amountController.text);
        if (amount == null) {
          throw ApiError(message: 'Enter a valid fare amount.');
        }

        final passengerDetails = _readPassengerDetails();
        draft = TicketIssueDraft(
          trip: _trip!,
          mode: _mode.apiValue,
          currency: _currency,
          amount: amount,
          passengerName: passengerDetails.name,
          passengerPhone: passengerDetails.phone,
        );
      }

      context.push('/tickets/issue/review', extra: draft);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Ticket'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trip == null
              ? EmptyStateView(
                  icon: Icons.directions_bus_outlined,
                  title: _error ?? 'No active trip',
                  action: AppButton(
                    label: 'Start trip',
                    onPressed: () => context.push('/trips/start'),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const IssueFlowStepHeader(
                        step: 1,
                        total: 3,
                        label: 'Ticket details',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _trip!.routeLabel,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text('Bus ${_trip!.fleetNumber ?? '—'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Ticket type', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      ...IssueTicketMode.values.map((mode) {
                        final selected = _mode == mode;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material(
                            color: selected
                                ? AppColors.brandRed.withValues(alpha: 0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: InkWell(
                              onTap: () => setState(() => _mode = mode),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.brandRed
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: selected
                                          ? AppColors.brandRed
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        mode.label,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Currency', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(hintText: 'Select currency'),
                        items: _currencies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Passenger details',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _passengerNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Passenger name',
                          hintText: 'Full name',
                          helperText: _mode == IssueTicketMode.luggage
                              ? 'Required to identify luggage owner'
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _passengerPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[+0-9\s()-]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Passenger phone',
                          hintText: '+263 77 123 4567',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_mode == IssueTicketMode.pair) ...[
                        Text('Passenger fare', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _passengerAmountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '$_currency ',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Luggage fare', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _luggageAmountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '$_currency ',
                          ),
                        ),
                      ] else ...[
                        Text('Fare amount', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter fare collected',
                            prefixText: '$_currency ',
                            helperText: 'Amount is entered by the conductor',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
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
                        label: 'Review ticket',
                        onPressed: _continueToReview,
                        icon: Icons.arrow_forward,
                      ),
                    ],
                  ),
                ),
    );
  }
}
