import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_spacing.dart';
import '../../data/local/database.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';

class PendingSyncScreen extends ConsumerStatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  ConsumerState<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends ConsumerState<PendingSyncScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(syncServiceProvider).retryAll(),
          ),
        ],
      ),
      body: FutureBuilder<_SyncViewData>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const EmptyStateView(
              icon: Icons.cloud_done_outlined,
              title: 'Everything is synced',
              subtitle: 'New offline tickets and trips will appear here until uploaded.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncServiceProvider).syncIfOnline(force: true);
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppButton(
                  label: 'Retry all (${data.items.length})',
                  onPressed: () => ref.read(syncServiceProvider).retryAll(),
                  icon: Icons.sync,
                ),
                const SizedBox(height: AppSpacing.md),
                ...data.items.map((item) => _SyncItemTile(
                      item: item,
                      onRetry: () => ref.read(syncServiceProvider).retryItem(item.id),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_SyncViewData> _load() async {
    final db = ref.read(appDatabaseProvider);
    final items = await db.getPendingSyncItems();
    final lastSync = await ref.read(syncServiceProvider).lastSyncAt();
    return _SyncViewData(items: items, lastSyncAt: lastSync);
  }
}

class _SyncViewData {
  _SyncViewData({required this.items, this.lastSyncAt});
  final List<SyncQueueItem> items;
  final DateTime? lastSyncAt;
}

class _SyncItemTile extends StatelessWidget {
  const _SyncItemTile({required this.item, required this.onRetry});

  final SyncQueueItem item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (item.entityType) {
      'trip' => 'Trip',
      'ticket' => 'Ticket',
      _ => item.entityType,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text('$typeLabel · ${item.operation.replaceAll('_', ' ')}'),
        subtitle: Text(
          'Ref ${item.entityId.substring(0, 8)}…\n'
          '${DateFormat.yMMMd().add_jm().format(item.createdAt)}'
          '${item.lastError != null ? '\n${item.lastError}' : ''}',
        ),
        isThreeLine: item.lastError != null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SyncStatusBadge(status: item.status),
            if (item.status == 'failed')
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
