import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// Conductors no longer end trips — cashiers close them in the admin console.
class EndTripScreen extends ConsumerStatefulWidget {
  const EndTripScreen({super.key});

  @override
  ConsumerState<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends ConsumerState<EndTripScreen> {
  TripModel? _trip;
  int _ticketCount = 0;
  double _revenue = 0;
  String _currency = 'USD';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
      if (trip == null) {
        setState(() => _error = 'No active trip.');
        return;
      }
      final stats =
          await ref.read(ticketRepositoryProvider).getTripStats(trip.id);
      setState(() {
        _trip = trip;
        _ticketCount = stats.count;
        _revenue = stats.revenue;
        _currency = stats.currency;
      });
    } catch (_) {
      setState(() => _error = 'Could not load trip details.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip status'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                  else if (trip != null) ...[
                    Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: AppColors.brandGold,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cashier closes this trip',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Keep selling tickets. When the run is finished, the '
                      'depot cashier ends the trip and prints the batch from '
                      'the CountryBoy admin console.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.routeLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Bus ${trip.fleetNumber ?? '—'}'),
                          Text(
                            'Started ${DateFormat.yMMMd().add_jm().format(trip.startedAt)}',
                          ),
                          Text('Tickets: $_ticketCount'),
                          Text(
                            'Sales: $_currency ${_revenue.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  AppButton(
                    label: 'Back to home',
                    onPressed: () => context.go('/home'),
                    icon: Icons.home_outlined,
                  ),
                ],
              ),
            ),
    );
  }
}
