import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/fare_currency.dart';
import '../../core/connectivity/online_sync_lifecycle.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../features/home/home_screen.dart';
import '../../shared/widgets/searchable_picker.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/issue_flow_step_header.dart';

/// UI issue modes mapped to backend `ticket_category` values.
enum IssueTicketMode {
  passenger('PASSENGER', 'Passenger', Icons.person_outline_rounded),
  combined(
    'PASSENGER_WITH_LUGGAGE',
    'Passenger + luggage',
    Icons.luggage_outlined,
  ),
  luggage('LUGGAGE', 'Luggage only', Icons.work_outline_rounded);

  const IssueTicketMode(this.apiValue, this.label, this.icon);
  final String apiValue;
  final String label;
  final IconData icon;

  bool get hasLuggage =>
      this == IssueTicketMode.combined || this == IssueTicketMode.luggage;

  bool get hasPassengerFare =>
      this == IssueTicketMode.passenger || this == IssueTicketMode.combined;
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

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  final _luggageAmountController = TextEditingController();
  final _luggageDescriptionController = TextEditingController();

  bool _loading = true;
  String? _error;
  int? _seenTripRevision;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _fareController.dispose();
    _luggageAmountController.dispose();
    _luggageDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When the device comes back online, trip may have been closed by cashier.
    ref.listen<int>(tripSessionRevisionProvider, (previous, next) {
      if (_seenTripRevision == next) return;
      _seenTripRevision = next;
      _load();
    });

    // Keep the original build body below — need to find the existing build method.
    return _buildBody(context);
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (!mounted) return;
      if (trip == null) {
        setState(() {
          _trip = null;
          _error =
              'No active trip. This trip may have been closed by the depot.';
        });
        return;
      }

      _originController.text = trip.routeOrigin?.trim() ?? '';
      _destinationController.text = trip.routeDestination?.trim() ?? '';

      setState(() => _trip = trip);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _passengerFare =>
      _mode.hasPassengerFare ? parseFareInput(_fareController.text) : null;

  double? get _luggageFare =>
      _mode.hasLuggage ? parseFareInput(_luggageAmountController.text) : null;

  double? get _totalAmount {
    switch (_mode) {
      case IssueTicketMode.passenger:
        return _passengerFare;
      case IssueTicketMode.luggage:
        return _luggageFare;
      case IssueTicketMode.combined:
        final p = _passengerFare;
        final l = _luggageFare;
        if (p == null || l == null) return null;
        return p + l;
    }
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _continueToReview() {
    if (_trip == null) return;
    setState(() => _error = null);

    try {
      final origin = _originController.text.trim();
      final destination = _destinationController.text.trim();

      if (origin.length < 2) {
        throw ApiError(message: 'Enter the passenger origin (at least 2 characters).');
      }
      if (destination.length < 2) {
        throw ApiError(
          message: 'Enter the passenger destination (at least 2 characters).',
        );
      }
      if (origin.toLowerCase() == destination.toLowerCase()) {
        throw ApiError(message: 'Origin and destination must be different.');
      }

      final luggageDescription = _optionalLuggageDescription();

      late TicketIssueDraft draft;

      switch (_mode) {
        case IssueTicketMode.passenger:
          final fare = _requireValidFare(_passengerFare, label: 'Fare');
          draft = TicketIssueDraft(
            trip: _trip!,
            mode: _mode.apiValue,
            currency: _currency,
            amount: fare,
            passengerAmount: fare,
            departure: origin,
            destination: destination,
          );
        case IssueTicketMode.luggage:
          final luggage = _requireValidFare(_luggageFare, label: 'Luggage amount');
          draft = TicketIssueDraft(
            trip: _trip!,
            mode: _mode.apiValue,
            currency: _currency,
            amount: luggage,
            luggageAmount: luggage,
            departure: origin,
            destination: destination,
            luggageDescription: luggageDescription,
          );
        case IssueTicketMode.combined:
          final passenger =
              _requireValidFare(_passengerFare, label: 'Passenger fare');
          final luggage =
              _requireValidFare(_luggageFare, label: 'Luggage amount');
          draft = TicketIssueDraft(
            trip: _trip!,
            mode: _mode.apiValue,
            currency: _currency,
            amount: passenger + luggage,
            passengerAmount: passenger,
            luggageAmount: luggage,
            departure: origin,
            destination: destination,
            luggageDescription: luggageDescription,
          );
      }

      context.push('/tickets/issue/review', extra: draft);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    }
  }

  double _requireValidFare(double? amount, {required String label}) {
    final error = validateFareAmount(_currency, amount, label: label);
    if (error != null) throw ApiError(message: error);
    return amount!.toDouble();
  }

  String? _optionalLuggageDescription() {
    if (!_mode.hasLuggage) return null;
    final description = _luggageDescriptionController.text.trim();
    if (description.isEmpty) return null;
    if (description.length < 2) {
      throw ApiError(message: 'Luggage description is too short.');
    }
    if (description.length > 80) {
      throw ApiError(message: 'Luggage description must be 80 characters or less.');
    }
    return description;
  }

  Future<void> _pickCurrency() async {
    final picked = await showCurrencyPickerSheet(
      context: context,
      currencies: kTicketCurrencies,
      selected: _currency,
      title: 'Select currency',
      subtitle: 'Fare rules change with the currency',
    );
    if (picked != null && mounted) {
      setState(() {
        _currency = picked;
        _error = null;
      });
    }
  }

  void _leaveIssueFlow() {
    // After "Issue another ticket" we land via go(), so there may be nothing to pop.
    // Always return to home — that is the entry point for issuing.
    ref.invalidate(homeDashboardProvider);
    context.go('/home');
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveIssueFlow();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Issue Ticket'),
        leading: BackButton(onPressed: _leaveIssueFlow),
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
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const IssueFlowStepHeader(
                              step: 1,
                              total: 3,
                              label: 'Ticket details',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _TripContextCard(trip: _trip!),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Ticket type',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...IssueTicketMode.values.map(_buildModeTile),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Passenger journey',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Enter this passenger’s origin and destination.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _originController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                _clearError();
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                labelText: 'Origin *',
                                hintText: 'e.g. Harare',
                                prefixIcon: Icon(Icons.trip_origin_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _destinationController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                _clearError();
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                labelText: 'Destination *',
                                hintText: 'e.g. Bulawayo',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SearchableSelectField(
                              label: 'Currency',
                              hint: 'Select currency',
                              valueText: currencyLabel(_currency),
                              leadingIcon: Icons.payments_outlined,
                              onTap: _pickCurrency,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text('Fare', style: theme.textTheme.labelLarge),
                            const SizedBox(height: AppSpacing.md),
                            if (_mode.hasPassengerFare) ...[
                              _AmountField(
                                controller: _fareController,
                                currency: _currency,
                                label: _mode == IssueTicketMode.combined
                                    ? 'Passenger fare *'
                                    : 'Fare amount *',
                                onChanged: () {
                                  _clearError();
                                  setState(() {});
                                },
                              ),
                              if (_mode == IssueTicketMode.combined)
                                const SizedBox(height: AppSpacing.md),
                            ],
                            if (_mode.hasLuggage) ...[
                              _AmountField(
                                controller: _luggageAmountController,
                                currency: _currency,
                                label: 'Luggage amount *',
                                onChanged: () {
                                  _clearError();
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _luggageDescriptionController,
                                maxLength: 80,
                                maxLines: 2,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (_) => _clearError(),
                                decoration: const InputDecoration(
                                  labelText: 'Luggage description',
                                  hintText: 'e.g. 2 bags, suitcase',
                                  helperText: 'Optional',
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                            if (_mode == IssueTicketMode.combined &&
                                _totalAmount != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _TotalBanner(
                                currency: _currency,
                                total: _totalAmount!,
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
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: AppButton(
                          label: 'Review ticket',
                          onPressed: _continueToReview,
                          icon: Icons.arrow_forward,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildModeTile(IssueTicketMode mode) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.brandRed.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => setState(() {
            _mode = mode;
            _error = null;
          }),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.brandRed : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  color: selected ? AppColors.brandRed : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    mode.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.brandRed : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripContextCard extends StatelessWidget {
  const _TripContextCard({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: AppColors.brandRed,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ${trip.fleetNumber ?? '—'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trip corridor: ${trip.routeLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String currency;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = parseFareInput(controller.text);
    final fieldError = parsed == null && controller.text.trim().isNotEmpty
        ? 'Enter a valid number'
        : validateFareAmount(currency, parsed, label: label.replaceAll(' *', ''));

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ],
      onChanged: (_) => onChanged(),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: currency == 'ZAR' ? '20' : '0',
        prefixText: '$currency ',
        errorText: controller.text.trim().isEmpty ? null : fieldError,
      ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.currency, required this.total});

  final String currency;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize_outlined, color: AppColors.brandRed),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'Passenger fare + luggage',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '$currency ${total.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.brandRed,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
