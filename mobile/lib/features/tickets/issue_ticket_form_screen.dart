import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/reference_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../shared/widgets/searchable_picker.dart';
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
  List<RouteModel> _subroutes = [];
  RouteModel? _selectedSubroute;
  IssueTicketMode _mode = IssueTicketMode.passenger;
  String _currency = 'USD';
  List<FareModel> _routeFares = [];
  FareModel? _routeFare;
  final _passengerPhoneController = TextEditingController();
  final _luggageAmountController = TextEditingController();
  bool _loading = true;
  bool _fareLoading = false;
  String? _error;
  String? _fareError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passengerPhoneController.dispose();
    _luggageAmountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (trip == null) {
        setState(() => _error = 'No active trip. Start a trip first.');
        return;
      }

      final referenceRepo = ref.read(referenceRepositoryProvider);
      await referenceRepo.refreshReferenceDataIfOnline();

      final options = await referenceRepo.getTicketRouteOptions(trip.routeId);
      if (options.isEmpty) {
        setState(() {
          _trip = trip;
          _subroutes = [
            RouteModel(
              id: trip.routeId,
              origin: trip.routeOrigin ?? 'Origin',
              destination: trip.routeDestination ?? 'Destination',
            ),
          ];
          _selectedSubroute = _subroutes.first;
        });
      } else {
        setState(() {
          _trip = trip;
          _subroutes = options;
          _selectedSubroute = options.firstWhere(
            (route) => route.id == trip.routeId,
            orElse: () => options.first,
          );
        });
      }
      await _loadRouteFares();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRouteFares() async {
    final trip = _trip;
    if (trip == null) return;
    final fareRouteId = _selectedSubroute?.id ?? trip.routeId;
    final fareRouteLabel = _selectedSubroute?.label ?? trip.routeLabel;

    setState(() {
      _fareLoading = true;
      _fareError = null;
    });

    try {
      final fares =
          await ref.read(referenceRepositoryProvider).getFaresForRoute(fareRouteId);
      if (fares.isEmpty) {
        setState(() {
          _routeFares = [];
          _routeFare = null;
          _fareError =
              'No fare configured for $fareRouteLabel. Contact your depot admin.';
        });
        return;
      }

      final currencies = fares.map((f) => f.currency).toSet().toList()..sort();
      final currency = currencies.contains(_currency)
          ? _currency
          : (currencies.contains('USD') ? 'USD' : currencies.first);
      final fare = fares.firstWhere((f) => f.currency == currency);

      setState(() {
        _routeFares = fares;
        _currency = currency;
        _routeFare = fare;
      });
    } on ApiError catch (e) {
      setState(() {
        _routeFares = [];
        _routeFare = null;
        _fareError = e.message;
      });
    } catch (_) {
      setState(() {
        _routeFares = [];
        _routeFare = null;
        _fareError = 'Unable to load route fare. Try again when online.';
      });
    } finally {
      setState(() => _fareLoading = false);
    }
  }

  void _onCurrencyChanged(String? currency) {
    if (currency == null || currency == _currency) return;
    final fare = _routeFares.cast<FareModel?>().firstWhere(
          (f) => f!.currency == currency,
          orElse: () => null,
        );
    if (fare == null) return;
    setState(() {
      _currency = currency;
      _routeFare = fare;
      _fareError = null;
    });
  }

  void _onSubrouteChanged(RouteModel? route) {
    if (route?.id == _selectedSubroute?.id) return;
    setState(() {
      _selectedSubroute = route;
      _routeFares = [];
      _routeFare = null;
      _fareError = null;
    });
    _loadRouteFares();
  }

  double? get _passengerFareAmount => _routeFare?.amount;

  double? get _luggageFareAmount {
    final raw = _luggageAmountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _amountForMode(IssueTicketMode mode) {
    switch (mode) {
      case IssueTicketMode.passenger:
      case IssueTicketMode.combined:
        return _passengerFareAmount;
      case IssueTicketMode.luggage:
        return _luggageFareAmount;
      case IssueTicketMode.pair:
        return null;
    }
  }

  double _requireLuggageAmount() {
    final amount = _luggageFareAmount;
    if (amount == null || amount <= 0) {
      throw ApiError(message: 'Enter the luggage amount before continuing.');
    }
    return amount;
  }

  ({String? phone}) _readOptionalPhone() {
    final phone = _passengerPhoneController.text.trim();
    if (phone.isEmpty) {
      return (phone: null);
    }
    if (phone.length < 7) {
      throw ApiError(message: 'Enter a valid passenger phone number (or leave blank).');
    }
    if (!RegExp(r'^[+]?[\d\s()-]+$').hasMatch(phone)) {
      throw ApiError(message: 'Phone number contains invalid characters.');
    }
    return (phone: phone);
  }

  void _continueToReview() {
    if (_trip == null) return;

    setState(() => _error = null);

    try {
      if (_routeFare == null) {
        throw ApiError(
          message: _fareError ?? 'Route fare is not available for this trip.',
        );
      }

      final phone = _readOptionalPhone().phone;
      final departure = _selectedSubroute?.origin ?? _trip!.routeOrigin;
      final destination = _selectedSubroute?.destination ?? _trip!.routeDestination;
      late TicketIssueDraft draft;

      if (_mode == IssueTicketMode.pair) {
        final passengerAmount = _passengerFareAmount;
        if (passengerAmount == null || passengerAmount <= 0) {
          throw ApiError(message: 'Route fare is not available for this trip.');
        }
        final luggageAmount = _requireLuggageAmount();

        draft = TicketIssueDraft(
          trip: _trip!,
          mode: _mode.apiValue,
          currency: _currency,
          passengerAmount: passengerAmount,
          luggageAmount: luggageAmount,
          departure: departure,
          destination: destination,
          passengerPhone: phone,
        );
      } else if (_mode == IssueTicketMode.luggage) {
        final amount = _requireLuggageAmount();

        draft = TicketIssueDraft(
          trip: _trip!,
          mode: _mode.apiValue,
          currency: _currency,
          amount: amount,
          departure: departure,
          destination: destination,
          passengerPhone: phone,
        );
      } else {
        final amount = _amountForMode(_mode);
        if (amount == null || amount <= 0) {
          throw ApiError(message: 'Route fare is not available for this trip.');
        }

        draft = TicketIssueDraft(
          trip: _trip!,
          mode: _mode.apiValue,
          currency: _currency,
          amount: amount,
          departure: departure,
          destination: destination,
          passengerPhone: phone,
        );
      }

      context.push('/tickets/issue/review', extra: draft);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    }
  }

  Widget _buildFareLine({
    required String label,
    required double amount,
    String? helper,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$_currency ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.brandRed,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLuggageAmountField() {
    return TextField(
      controller: _luggageAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: 'Luggage amount *',
        hintText: '0.00',
        prefixText: '$_currency ',
        helperText: 'Enter the luggage charge for this ticket',
      ),
    );
  }

  Widget _buildRouteFareSection() {
    if (_fareLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fareError != null) {
      return Card(
        color: AppColors.error.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _fareError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final passengerFare = _passengerFareAmount;
    final luggageFare = _luggageFareAmount;

    if (_mode == IssueTicketMode.pair) {
      if (passengerFare == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFareLine(
            label: 'Passenger fare',
            amount: passengerFare,
            helper: 'From route fare',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLuggageAmountField(),
          if (luggageFare != null && luggageFare > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '$_currency ${(passengerFare + luggageFare).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (_mode == IssueTicketMode.luggage) {
      return _buildLuggageAmountField();
    }

    if (passengerFare == null) return const SizedBox.shrink();

    final amount = _amountForMode(_mode)!;
    final fareRouteLabel = _selectedSubroute?.label ?? _trip!.routeLabel;

    return _buildFareLine(
      label: 'Fare amount',
      amount: amount,
      helper: 'From route fare for $fareRouteLabel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCurrencies =
        _routeFares.map((f) => f.currency).toSet().toList()..sort();

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
                      SearchableSelectField(
                        label: 'Ticket section',
                        hint: 'Search corridor or segment',
                        enabled: !_fareLoading && _subroutes.isNotEmpty,
                        valueText: _selectedSubroute == null
                            ? null
                            : '${_selectedSubroute!.origin}  →  ${_selectedSubroute!.destination}',
                        subtitle: _selectedSubroute?.hasParents == true
                            ? 'Linked segment'
                            : _selectedSubroute == null
                                ? null
                                : 'Full trip corridor',
                        leadingIcon: Icons.alt_route_rounded,
                        onTap: () async {
                          if (_subroutes.isEmpty) return;
                          final picked = await showRoutePickerSheet(
                            context: context,
                            routes: _subroutes,
                            selected: _selectedSubroute,
                            title: 'Ticket section',
                            subtitle:
                                'Choose the full corridor or a linked segment for this ticket.',
                            searchHint: 'Search origin or destination',
                          );
                          if (picked != null && mounted) {
                            _onSubrouteChanged(picked);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Each corridor segment uses its own fare.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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
                              onTap: () => setState(() {
                                _mode = mode;
                                _error = null;
                              }),
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
                      if (availableCurrencies.isNotEmpty) ...[
                        SearchableSelectField(
                          label: 'Currency',
                          hint: 'Select currency',
                          enabled: !_fareLoading,
                          valueText: availableCurrencies.contains(_currency)
                              ? _currency
                              : availableCurrencies.first,
                          leadingIcon: Icons.payments_outlined,
                          onTap: () async {
                            final current =
                                availableCurrencies.contains(_currency)
                                    ? _currency
                                    : availableCurrencies.first;
                            final picked = await showCurrencyPickerSheet(
                              context: context,
                              currencies: availableCurrencies,
                              selected: current,
                              title: 'Select currency',
                              subtitle: 'Currencies available for this route fare',
                            );
                            if (picked != null && mounted) {
                              _onCurrencyChanged(picked);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Text(
                        'Contact (optional)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _passengerPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[+0-9\s()-]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Passenger phone',
                          hintText: '+263 77 123 4567',
                          helperText: 'Optional — leave blank if not provided',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Fare', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRouteFareSection(),
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
                        onPressed: _routeFare == null || _fareLoading
                            ? null
                            : _continueToReview,
                        icon: Icons.arrow_forward,
                      ),
                    ],
                  ),
                ),
    );
  }
}
