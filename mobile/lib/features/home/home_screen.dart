import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';

final homeDashboardProvider = FutureProvider<_DashboardData>((ref) async {
  final agent = await ref.read(authRepositoryProvider).getCurrentAgent();
  final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
  final pending = await ref.read(syncServiceProvider).pendingCount();
  final today = await ref.read(ticketRepositoryProvider).getTodayTickets();
  return _DashboardData(
    agent: agent,
    activeTrip: trip,
    pendingCount: pending,
    todayCount: today.length,
  );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).syncIfOnline();
    });
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final time = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return '$time, $name';
  }

  Future<void> _refreshDashboard() async {
    await ref.read(syncServiceProvider).syncIfOnline(force: true);
    ref.invalidate(homeDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(homeDashboardProvider);

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load dashboard'),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Retry', onPressed: _refreshDashboard),
          ],
        ),
      ),
      data: (data) {
        final agent = data.agent;
        final trip = data.activeTrip;
        final pending = data.pendingCount;
        final todayTickets = data.todayCount;

        return RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(agent?.firstName ?? 'Conductor'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (agent != null)
                          Text(
                            '${agent.depotName} · ${agent.agentCode}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (context.mounted) context.go('/login/merchant');
                    },
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (trip != null) ...[
                _ActiveTripCard(trip: trip),
                const SizedBox(height: AppSpacing.sm),
                ActionCard(
                  icon: Icons.stop_circle_outlined,
                  title: 'End Trip',
                  subtitle: '${trip.ticketsCount} tickets · ${trip.totalRevenue.toStringAsFixed(2)}',
                  onTap: () => context.push('/trips/end'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _StatChip(label: 'Today', value: '$todayTickets tickets')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _StatChip(label: 'Pending sync', value: '$pending')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ActionCard(
                icon: Icons.play_circle_outline,
                title: trip == null ? 'Start Trip' : 'Trip in progress',
                subtitle: trip == null
                    ? 'Select bus and route to begin'
                    : '${trip.fleetNumber} · ${trip.routeLabel}',
                highlight: trip == null,
                onTap: trip == null
                    ? () => context.push('/trips/start')
                    : () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionCard(
                icon: Icons.confirmation_number_outlined,
                title: 'Issue Ticket',
                subtitle: trip == null
                    ? 'Start a trip first'
                    : 'Sell passenger or luggage ticket',
                onTap: trip == null ? () {} : () => context.push('/tickets/issue'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionCard(
                icon: Icons.receipt_long_outlined,
                title: 'Issued Tickets',
                subtitle: 'View tickets for this device',
                onTap: () => context.go('/tickets'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionCard(
                icon: Icons.cloud_upload_outlined,
                title: 'Pending Sync',
                subtitle: pending == 0 ? 'Everything is synced' : '$pending items waiting',
                onTap: () => context.go('/sync'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.agent,
    required this.activeTrip,
    required this.pendingCount,
    required this.todayCount,
  });

  final dynamic agent;
  final dynamic activeTrip;
  final int pendingCount;
  final int todayCount;
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});

  final dynamic trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.brandRed.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: AppColors.brandRed),
                const SizedBox(width: AppSpacing.sm),
                Text('Active trip', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                SyncStatusBadge(status: trip.syncStatus as String),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(trip.routeLabel as String, style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Bus ${trip.fleetNumber} · Started ${DateFormat.jm().format(trip.startedAt as DateTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if ((trip.ticketsCount as int) > 0)
              Text(
                '${trip.ticketsCount} tickets · ${(trip.totalRevenue as num).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
