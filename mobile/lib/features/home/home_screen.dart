import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/connectivity/online_sync_lifecycle.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';

final homeDashboardProvider = FutureProvider<_DashboardData>((ref) async {
  // Refresh when reconnect lifecycle bumps trip session (cashier end, etc.).
  ref.watch(tripSessionRevisionProvider);

  AgentProfile? agent;
  TripModel? trip;
  var pending = 0;

  try {
    agent = await ref.read(authRepositoryProvider).getCurrentAgent();
  } catch (_) {}

  try {
    trip = await ref.read(tripRepositoryProvider).getActiveTrip();
  } catch (_) {}

  try {
    pending = await ref.read(syncServiceProvider).pendingCount();
  } catch (_) {}

  return _DashboardData(
    agent: agent,
    activeTrip: trip,
    pendingCount: pending,
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
    final time =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return '$time, $name';
  }

  String _agentFirstName(AgentProfile? agent) {
    final name = agent?.firstName.trim() ?? '';
    return name.isEmpty ? 'Conductor' : name;
  }

  String? _agentDepotLabel(AgentProfile? agent) {
    if (agent == null) return null;
    final parts = <String>[
      if (agent.depotName.trim().isNotEmpty) agent.depotName.trim(),
      if (agent.agentCode.trim().isNotEmpty) agent.agentCode.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Future<void> _refreshDashboard() async {
    await ref.read(syncServiceProvider).syncIfOnline(force: true);
    ref.invalidate(homeDashboardProvider);
    ref.read(tripSessionRevisionProvider.notifier).state++;
  }

  Future<void> _confirmLogout() async {
    final online =
        await ref.read(connectivityServiceProvider).checkReachability();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          online
              ? 'After you sign out, you will not be able to sign in again without internet — even if offline sign in was enabled. Sign out only if you can get online to log back in.'
              : 'You are offline. If you sign out now, you will not be able to sign back in until this device is online again. Stay signed in if you still need to issue tickets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login/merchant');
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(homeDashboardProvider);
    final connectivity = ref.watch(connectivityStatusProvider);

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Retry', onPressed: _refreshDashboard),
            ],
          ),
        ),
      ),
      data: (data) {
        final agent = data.agent;
        final trip = data.activeTrip;
        final pending = data.pendingCount;

        return RefreshIndicator(
          color: AppColors.brandRed,
          onRefresh: _refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              connectivity.when(
                data: (status) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ConnectivityBanner(status: status),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              _HomeHeader(
                greeting: _greeting(_agentFirstName(agent)),
                depotLabel: _agentDepotLabel(agent),
                onLogout: _confirmLogout,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (trip != null) ...[
                _ActiveTripCard(trip: trip),
                const SizedBox(height: AppSpacing.md),
              ] else
                const _NoTripCard(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (trip == null) ...[
                _HomeActionTile(
                  icon: Icons.play_circle_outline,
                  title: 'Start Trip',
                  subtitle: 'Select bus, driver and corridor',
                  emphasized: true,
                  onTap: () => context.push('/trips/start'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else ...[
                _HomeInfoTile(
                  icon: Icons.schedule_outlined,
                  title: 'Trip in progress',
                  subtitle:
                      'The depot cashier closes this trip from the admin console.',
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _HomeActionTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Issue Ticket',
                subtitle: trip == null
                    ? 'Start a trip first'
                    : 'Sell passenger or luggage ticket',
                enabled: trip != null,
                onTap: trip == null
                    ? null
                    : () => context.push('/tickets/issue'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _HomeActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Sales & Tickets',
                subtitle: 'Trip totals and ticket types',
                onTap: () => context.go('/tickets'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _HomeActionTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Pending Sync',
                subtitle: pending == 0
                    ? 'Everything is synced'
                    : '$pending items waiting',
                badge: pending > 0 ? '$pending' : null,
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
  });

  final AgentProfile? agent;
  final TripModel? activeTrip;
  final int pendingCount;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.depotLabel,
    required this.onLogout,
  });

  final String greeting;
  final String? depotLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              if (depotLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    depotLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.brandRed,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoTripCard extends StatelessWidget {
  const _NoTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.directions_bus_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active trip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Start a trip to begin issuing tickets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.brandRed.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: AppColors.brandRed,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Active trip',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.brandRed,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'Live',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SyncStatusBadge(status: trip.syncStatus),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      trip.routeLabel,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bus ${trip.fleetNumber ?? '—'} · Started ${DateFormat.jm().format(trip.startedAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Tickets',
                  value: '${trip.ticketsCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: 'Trip sales',
                  value: trip.totalRevenue.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HomeInfoTile extends StatelessWidget {
  const _HomeInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.brandGold, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.emphasized = false,
    this.enabled = true,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool emphasized;
  final bool enabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onTap != null;
    final iconBg = emphasized
        ? AppColors.brandRed.withValues(alpha: 0.12)
        : AppColors.brandRed.withValues(alpha: 0.08);
    final borderColor = emphasized
        ? AppColors.brandRed.withValues(alpha: 0.35)
        : AppColors.border;

    return Opacity(
      opacity: interactive ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: interactive ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: AppColors.brandRed, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              margin: const EdgeInsets.only(left: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pendingSync
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                badge!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.pendingSync,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: interactive
                        ? AppColors.brandRed
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
