import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../data/local/database.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';
import 'sync_queue_display.dart';

class PendingSyncScreen extends ConsumerStatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  ConsumerState<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends ConsumerState<PendingSyncScreen> {
  Future<_SyncViewData>? _future;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<_SyncViewData> _load() async {
    final db = ref.read(appDatabaseProvider);
    final items = await db.getPendingSyncItems();
    final displayItems = await buildSyncQueueDisplayItems(db, items);
    final lastSync = await ref.read(syncServiceProvider).lastSyncAt();
    return _SyncViewData(items: displayItems, lastSyncAt: lastSync);
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await ref.read(syncServiceProvider).syncIfOnline(force: true);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      final data = await _future;
      if (!mounted) return;
      final remaining = data?.items.length ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining == 0
                ? 'Everything is synced.'
                : '$remaining item${remaining == 1 ? '' : 's'} still waiting.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _retryAll() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await ref.read(syncServiceProvider).retryAll();
      if (!mounted) return;
      await _reload();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _retryItem(int id) async {
    await ref.read(syncServiceProvider).retryItem(id);
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Sync'),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: Column(
        children: [
          connectivity.when(
            data: (status) => ConnectivityBanner(status: status),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: FutureBuilder<_SyncViewData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null) {
                  return EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load sync queue',
                    action: AppButton(label: 'Retry', onPressed: _reload),
                  );
                }

                final items = data.items;
                final failed =
                    items.where((item) => item.isFailed).length;
                final pending = items
                    .where((item) => item.item.status == 'pending')
                    .length;
                final ticketCount =
                    items.where((item) => !item.isTrip).length;
                final tripCount = items.where((item) => item.isTrip).length;

                return RefreshIndicator(
                  color: AppColors.brandRed,
                  onRefresh: () async {
                    await ref
                        .read(syncServiceProvider)
                        .syncIfOnline(force: true);
                    await _reload();
                  },
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            _SyncSummaryCard(
                              total: 0,
                              pending: 0,
                              failed: 0,
                              lastSyncAt: data.lastSyncAt,
                            ),
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.35,
                              child: const EmptyStateView(
                                icon: Icons.cloud_done_outlined,
                                title: 'Everything is synced',
                                subtitle:
                                    'Offline tickets and trips will appear here until they upload.',
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          children: [
                            _SyncSummaryCard(
                              total: items.length,
                              pending: pending,
                              failed: failed,
                              lastSyncAt: data.lastSyncAt,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: _syncing
                                  ? 'Syncing…'
                                  : 'Sync now (${items.length})',
                              onPressed: _syncing ? null : _syncNow,
                              loading: _syncing,
                              icon: Icons.cloud_upload_outlined,
                            ),
                            if (failed > 0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppButton(
                                label: 'Retry failed ($failed)',
                                outlined: true,
                                onPressed: _syncing ? null : _retryAll,
                                icon: Icons.refresh,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Queue',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _queueSubtitle(
                                ticketCount: ticketCount,
                                tripCount: tripCount,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...items.map(
                              (display) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _SyncItemTile(
                                  display: display,
                                  onRetry: () =>
                                      _retryItem(display.item.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _queueSubtitle({required int ticketCount, required int tripCount}) {
  final parts = <String>[];
  if (ticketCount > 0) {
    parts.add('$ticketCount ticket${ticketCount == 1 ? '' : 's'}');
  }
  if (tripCount > 0) {
    parts.add('$tripCount trip${tripCount == 1 ? '' : 's'}');
  }
  if (parts.isEmpty) return 'Oldest items are listed first';
  return '${parts.join(' · ')} waiting · oldest first';
}

class _SyncViewData {
  _SyncViewData({required this.items, this.lastSyncAt});
  final List<SyncQueueDisplayItem> items;
  final DateTime? lastSyncAt;
}

class _SyncSummaryCard extends StatelessWidget {
  const _SyncSummaryCard({
    required this.total,
    required this.pending,
    required this.failed,
    required this.lastSyncAt,
  });

  final int total;
  final int pending;
  final int failed;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastSyncLabel = lastSyncAt == null
        ? 'Not synced yet'
        : 'Last sync ${DateFormat.MMMd().add_jm().format(lastSyncAt!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
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
                  color: total == 0
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  total == 0
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                  color: total == 0 ? AppColors.success : AppColors.brandRed,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0 ? 'All clear' : 'Waiting to upload',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastSyncLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SyncStatBox(
                  label: 'Total',
                  value: '$total',
                  accent: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SyncStatBox(
                  label: 'Pending',
                  value: '$pending',
                  accent: AppColors.pendingSync,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SyncStatBox(
                  label: 'Failed',
                  value: '$failed',
                  accent: failed > 0 ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncStatBox extends StatelessWidget {
  const _SyncStatBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SyncItemTile extends StatelessWidget {
  const _SyncItemTile({
    required this.display,
    required this.onRetry,
  });

  final SyncQueueDisplayItem display;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = display.item;
    final isFailed = display.isFailed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFailed
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  display.isTrip
                      ? Icons.directions_bus_outlined
                      : Icons.confirmation_number_outlined,
                  color: isFailed ? AppColors.error : AppColors.brandRed,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (display.routeLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        display.routeLabel!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (display.detailLine != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        display.detailLine!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (item.retryCount > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Retries ${item.retryCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SyncStatusBadge(status: item.status),
            ],
          ),
          if (item.lastError != null && item.lastError!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                item.lastError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          if (isFailed) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandRed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
