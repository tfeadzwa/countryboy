import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/reference_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../features/home/home_screen.dart';
import '../../domain/models/models.dart';
import '../../shared/widgets/searchable_picker.dart';
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
      await ref.read(referenceRepositoryProvider).refreshReferenceDataIfOnline();
      final routes = await ref.read(referenceRepositoryProvider).getMainRoutes();
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
                  SearchableSelectField(
                    label: 'Bus / fleet',
                    hint: 'Search and choose bus',
                    valueText: _selectedFleet?.number,
                    subtitle: _selectedFleet?.status,
                    leadingIcon: Icons.directions_bus_rounded,
                    onTap: () async {
                      final fleets = _fleets ?? [];
                      if (fleets.isEmpty) return;
                      final picked = await showFleetPickerSheet(
                        context: context,
                        fleets: fleets,
                        selected: _selectedFleet,
                        title: 'Select bus',
                        subtitle: 'Search by fleet number',
                      );
                      if (picked != null && mounted) {
                        setState(() => _selectedFleet = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SearchableSelectField(
                    label: 'Route',
                    hint: 'Search and choose route',
                    valueText: _selectedRoute == null
                        ? null
                        : '${_selectedRoute!.origin}  →  ${_selectedRoute!.destination}',
                    leadingIcon: Icons.alt_route_rounded,
                    onTap: () async {
                      final routes = _routes ?? [];
                      if (routes.isEmpty) return;
                      final picked = await showRoutePickerSheet(
                        context: context,
                        routes: routes,
                        selected: _selectedRoute,
                        title: 'Select route',
                        subtitle: 'Search by origin or destination',
                      );
                      if (picked != null && mounted) {
                        setState(() => _selectedRoute = picked);
                      }
                    },
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
                            Text(
                              'Route: ${_selectedRoute!.origin}  →  ${_selectedRoute!.destination}',
                            ),
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
