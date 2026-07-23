import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
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
  FleetModel? _selectedFleet;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fleets = await ref.read(referenceRepositoryProvider).getFleets();
      setState(() => _fleets = fleets);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_selectedFleet == null) {
      setState(() => _error = 'Select a bus');
      return;
    }

    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.length < 2) {
      setState(() => _error = 'Enter the trip origin (at least 2 characters).');
      return;
    }
    if (destination.length < 2) {
      setState(
        () => _error = 'Enter the trip destination (at least 2 characters).',
      );
      return;
    }
    if (origin.toLowerCase() == destination.toLowerCase()) {
      setState(() => _error = 'Origin and destination must be different.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(tripRepositoryProvider).startTrip(
            fleetId: _selectedFleet!.id,
            fleetNumber: _selectedFleet!.number,
            origin: origin,
            destination: destination,
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
    final theme = Theme.of(context);
    final canPreview = _selectedFleet != null &&
        _originController.text.trim().length >= 2 &&
        _destinationController.text.trim().length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Trip'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bus & corridor',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pick the bus from your depot fleet, then type this '
                          'trip’s origin and destination.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
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
                              setState(() {
                                _selectedFleet = picked;
                                _error = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Trip corridor',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Enter where this trip is running from and to.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _originController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() => _error = null),
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
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() => _error = null),
                          decoration: const InputDecoration(
                            labelText: 'Destination *',
                            hintText: 'e.g. Bulawayo',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                        if (canPreview) ...[
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
                                  'Trip summary',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Bus: ${_selectedFleet!.number}'),
                                Text(
                                  'Corridor: ${_originController.text.trim()}'
                                  '  →  ${_destinationController.text.trim()}',
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      label: 'Start Trip',
                      loading: _submitting,
                      onPressed: _start,
                      icon: Icons.play_arrow,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
