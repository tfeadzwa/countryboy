import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../features/home/home_screen.dart';
import '../../domain/models/models.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';

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
  bool _ending = false;
  TripEndSummary? _summary;
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
        setState(() => _error = 'No active trip to end.');
        return;
      }
      final stats = await ref.read(ticketRepositoryProvider).getTripStats(trip.id);
      setState(() {
        _trip = trip;
        _ticketCount = stats.count;
        _revenue = stats.revenue;
        _currency = stats.currency;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmEnd() async {
    if (_trip == null || _ending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this trip?'),
        content: Text(
          'You issued $_ticketCount ticket(s) for $_currency ${_revenue.toStringAsFixed(2)}. '
          'You cannot issue more tickets after ending.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End trip'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _ending = true;
      _error = null;
    });

    try {
      final summary = await ref.read(tripRepositoryProvider).endTrip(_trip!.id);
      ref.read(syncServiceProvider).syncIfOnline();
      ref.invalidate(homeDashboardProvider);
      setState(() => _summary = summary);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not end trip. Try again.');
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_summary != null ? 'Trip complete' : 'End Trip'),
        leading: BackButton(
          onPressed: () => _summary != null ? context.go('/home') : context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _summary != null
              ? _SummaryView(summary: _summary!)
              : _trip == null
                  ? EmptyStateView(
                      icon: Icons.directions_bus_outlined,
                      title: _error ?? 'No active trip',
                      action: AppButton(label: 'Back to home', onPressed: () => context.go('/home')),
                    )
                  : _ConfirmView(
                      trip: _trip!,
                      ticketCount: _ticketCount,
                      revenue: _revenue,
                      currency: _currency,
                      error: _error,
                      ending: _ending,
                      onEnd: _confirmEnd,
                    ),
    );
  }
}

class _ConfirmView extends StatelessWidget {
  const _ConfirmView({
    required this.trip,
    required this.ticketCount,
    required this.revenue,
    required this.currency,
    required this.ending,
    required this.onEnd,
    this.error,
  });

  final TripModel trip;
  final int ticketCount;
  final double revenue;
  final String currency;
  final bool ending;
  final VoidCallback onEnd;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Trip summary', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.routeLabel, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _Row(label: 'Bus', value: trip.fleetNumber ?? '—'),
                  _Row(
                    label: 'Started',
                    value: DateFormat.yMMMd().add_jm().format(trip.startedAt),
                  ),
                  _Row(label: 'Tickets issued', value: '$ticketCount'),
                  _Row(
                    label: 'Revenue',
                    value: '$currency ${revenue.toStringAsFixed(2)}',
                  ),
                  if (trip.syncStatus != 'synced') ...[
                    const SizedBox(height: AppSpacing.sm),
                    SyncStatusBadge(status: trip.syncStatus),
                  ],
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
          const Spacer(),
          AppButton(
            label: 'End Trip',
            loading: ending,
            icon: Icons.stop_circle_outlined,
            onPressed: onEnd,
          ),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final TripEndSummary summary;

  @override
  Widget build(BuildContext context) {
    final hours = summary.duration.inHours;
    final minutes = summary.duration.inMinutes.remainder(60);
    final durationLabel = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Trip ended',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.routeLabel, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _Row(label: 'Bus', value: summary.fleetNumber),
                  _Row(label: 'Duration', value: durationLabel),
                  _Row(label: 'Tickets', value: '${summary.totalTickets}'),
                  _Row(
                    label: 'Total revenue',
                    value: '${summary.currency} ${summary.totalRevenue.toStringAsFixed(2)}',
                  ),
                  _Row(
                    label: 'Ended at',
                    value: DateFormat.yMMMd().add_jm().format(summary.endedAt),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SyncStatusBadge(status: summary.syncStatus),
                  if (summary.syncStatus != 'synced')
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Trip end will sync when connection returns.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Back to Home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
