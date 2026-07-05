import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/reference_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../features/home/home_screen.dart';
import '../../domain/models/models.dart';
import '../../shared/widgets/widgets.dart';

class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key});

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  List<FleetModel>? _fleets;
  List<RouteModel>? _routes;
  FleetModel? _selectedFleet;
  RouteModel? _selectedRoute;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fleets = await ref.read(referenceRepositoryProvider).getFleets();
      final routes = await ref.read(referenceRepositoryProvider).getRoutes();
      setState(() {
        _fleets = fleets;
        _routes = routes;
      });
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_selectedFleet == null || _selectedRoute == null) {
      setState(() => _error = 'Select a bus and route');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(tripRepositoryProvider).startTrip(
            fleetId: _selectedFleet!.id,
            routeId: _selectedRoute!.id,
            fleetNumber: _selectedFleet!.number,
            routeOrigin: _selectedRoute!.origin,
            routeDestination: _selectedRoute!.destination,
          );
      ref.invalidate(homeDashboardProvider);
      if (mounted) context.go('/home');
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not start trip. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Trip'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select bus and route',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text('Bus / fleet', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<FleetModel>(
                    value: _selectedFleet,
                    decoration: const InputDecoration(hintText: 'Choose bus'),
                    items: (_fleets ?? [])
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.number),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFleet = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Route', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<RouteModel>(
                    value: _selectedRoute,
                    decoration: const InputDecoration(hintText: 'Choose route'),
                    items: (_routes ?? [])
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRoute = v),
                  ),
                  const Spacer(),
                  if (_selectedFleet != null && _selectedRoute != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip summary', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Bus: ${_selectedFleet!.number}'),
                            Text('Route: ${_selectedRoute!.label}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Start Trip',
                    loading: _submitting,
                    onPressed: _start,
                    icon: Icons.play_arrow,
                  ),
                ],
              ),
            ),
    );
  }
}
