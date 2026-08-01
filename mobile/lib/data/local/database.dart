import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(
  tables: [
    CachedFleets,
    CachedDrivers,
    CachedRoutes,
    CachedFares,
    LocalTrips,
    LocalTickets,
    SyncQueueItems,
    SyncMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(localTickets, localTickets.passengerName);
            await m.addColumn(localTickets, localTickets.passengerPhone);
          }
          if (from < 4) {
            // Schema 3 used a single parent_route_id column. Rebuild cache table
            // for multi-parent JSON fields; next online sync will refill rows.
            await m.deleteTable('cached_routes');
            await m.createTable(cachedRoutes);
          }
          if (from < 5) {
            await m.addColumn(localTickets, localTickets.luggageDescription);
          }
          if (from < 6) {
            await m.addColumn(localTickets, localTickets.luggageAmount);
          }
          if (from < 7) {
            // Recreate local trips so routeId can be nullable (manual corridors).
            await m.deleteTable('local_trips');
            await m.createTable(localTrips);
          }
          if (from < 8) {
            await m.createTable(cachedDrivers);
            await m.addColumn(localTrips, localTrips.driverId);
            await m.addColumn(localTrips, localTrips.driverName);
          }
          if (from < 9) {
            await m.deleteTable('cached_drivers');
            await m.createTable(cachedDrivers);
          }
          if (from < 10) {
            await m.addColumn(localTickets, localTickets.printed);
            await m.addColumn(localTickets, localTickets.printedAt);
          }
          if (from < 11) {
            await m.addColumn(cachedFleets, cachedFleets.registrationNumber);
            await m.addColumn(localTrips, localTrips.fleetRegistrationNumber);
          }
          if (from < 12) {
            await m.addColumn(cachedFleets, cachedFleets.onTrip);
            await m.addColumn(cachedDrivers, cachedDrivers.onTrip);
          }
          if (from < 13) {
            await m.addColumn(localTrips, localTrips.startingMileage);
            await m.addColumn(localTrips, localTrips.waybillNo);
            await m.addColumn(localTrips, localTrips.closingMileage);
          }
        },
      );

  // ── Reference cache ──────────────────────────────────────────────

  Future<void> cacheFleets(List<CachedFleetsCompanion> items) async {
    await transaction(() async {
      await delete(cachedFleets).go();
      if (items.isNotEmpty) {
        await batch((b) => b.insertAll(cachedFleets, items));
      }
    });
  }

  Future<List<CachedFleet>> getCachedFleets() =>
      (select(cachedFleets)..orderBy([(t) => OrderingTerm.asc(t.number)])).get();

  Future<void> setFleetOnTrip(String fleetId, bool onTrip) async {
    await (update(cachedFleets)..where((t) => t.id.equals(fleetId))).write(
      CachedFleetsCompanion(onTrip: Value(onTrip)),
    );
  }

  Future<void> cacheDrivers(List<CachedDriversCompanion> items) async {
    await transaction(() async {
      await delete(cachedDrivers).go();
      if (items.isNotEmpty) {
        await batch((b) => b.insertAll(cachedDrivers, items));
      }
    });
  }

  Future<List<CachedDriver>> getCachedDrivers() => (select(cachedDrivers)
        ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
      .get();

  Future<void> setDriverOnTrip(String driverId, bool onTrip) async {
    await (update(cachedDrivers)..where((t) => t.id.equals(driverId))).write(
      CachedDriversCompanion(onTrip: Value(onTrip)),
    );
  }

  Future<void> cacheRoutes(List<CachedRoutesCompanion> items) async {
    await transaction(() async {
      await delete(cachedRoutes).go();
      if (items.isNotEmpty) {
        await batch((b) => b.insertAll(cachedRoutes, items));
      }
    });
  }

  Future<List<CachedRoute>> getCachedRoutes() => (select(cachedRoutes)
        ..where((r) => r.isActive.equals(true))
        ..orderBy([(r) => OrderingTerm.asc(r.origin)]))
      .get();

  Future<void> cacheFares(List<CachedFaresCompanion> items) async {
    await transaction(() async {
      await delete(cachedFares).go();
      if (items.isNotEmpty) {
        await batch((b) => b.insertAll(cachedFares, items));
      }
    });
  }

  Future<List<CachedFare>> getCachedFares() => select(cachedFares).get();

  Future<CachedFare?> getFareForRoute(String routeId, {String currency = 'USD'}) {
    return (select(cachedFares)
          ..where(
            (f) => f.routeId.equals(routeId) & f.currency.equals(currency),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ── Trips ────────────────────────────────────────────────────────

  Future<void> upsertTrip(LocalTripsCompanion trip) =>
      into(localTrips).insertOnConflictUpdate(trip);

  Future<LocalTrip?> getActiveTrip(String agentId) {
    return (select(localTrips)
          ..where(
            (t) => t.agentId.equals(agentId) & t.status.equals('ACTIVE'),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LocalTrip?> getTripById(String id) =>
      (select(localTrips)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateTripSyncStatus(String id, String status) =>
      (update(localTrips)..where((t) => t.id.equals(id)))
          .write(LocalTripsCompanion(syncStatus: Value(status)));

  Future<void> completeTrip(String id) =>
      (update(localTrips)..where((t) => t.id.equals(id))).write(
        LocalTripsCompanion(
          status: const Value('COMPLETED'),
          endedAt: Value(DateTime.now()),
        ),
      );

  /// Marks a trip as ended locally (cashier/admin close, or pull reconcile).
  Future<void> markTripEnded(
    String id, {
    String status = 'ENDED',
    DateTime? endedAt,
  }) =>
      (update(localTrips)..where((t) => t.id.equals(id))).write(
        LocalTripsCompanion(
          status: Value(status),
          endedAt: Value(endedAt ?? DateTime.now()),
          syncStatus: const Value('synced'),
        ),
      );

  /// Ends every local ACTIVE trip for an agent (server has none / trip closed).
  Future<void> markAgentActiveTripsEnded(
    String agentId, {
    String status = 'ENDED',
    DateTime? endedAt,
  }) =>
      (update(localTrips)
            ..where(
              (t) => t.agentId.equals(agentId) & t.status.equals('ACTIVE'),
            ))
          .write(
        LocalTripsCompanion(
          status: Value(status),
          endedAt: Value(endedAt ?? DateTime.now()),
          syncStatus: const Value('synced'),
        ),
      );

  // ── Tickets ──────────────────────────────────────────────────────

  Future<void> insertTicket(LocalTicketsCompanion ticket) =>
      into(localTickets).insert(ticket);

  /// Insert or update a ticket from a server pull (cross-device sync).
  Future<void> upsertTicket(LocalTicketsCompanion ticket) =>
      into(localTickets).insertOnConflictUpdate(ticket);

  Future<bool> ticketExistsByIdempotencyKey(String key) async {
    final row = await (select(localTickets)
          ..where((t) => t.idempotencyKey.equals(key))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<LocalTicket>> getAllTickets({String? tripId}) {
    final query = select(localTickets)
      ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]);
    if (tripId != null) {
      query.where((t) => t.tripId.equals(tripId));
    }
    return query.get();
  }

  Future<List<LocalTicket>> getTicketsForToday() {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    return (select(localTickets)
          ..where((t) => t.issuedAt.isBiggerOrEqualValue(dayStart))
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .get();
  }

  Future<int> countPendingTickets() async {
    final rows = await (select(localTickets)
          ..where((t) => t.syncStatus.isNotIn(['synced'])))
        .get();
    return rows.length;
  }

  Future<void> updateTicketSyncStatus(
    String id,
    String status, {
    int? serialNumber,
    String? error,
  }) {
    return (update(localTickets)..where((t) => t.id.equals(id))).write(
      LocalTicketsCompanion(
        syncStatus: Value(status),
        serialNumber:
            serialNumber != null ? Value(serialNumber) : const Value.absent(),
        lastError: error != null ? Value(error) : const Value.absent(),
      ),
    );
  }

  Future<void> markTicketsPrinted(List<String> ids, {DateTime? printedAt}) {
    if (ids.isEmpty) return Future.value();
    final when = printedAt ?? DateTime.now();
    return (update(localTickets)..where((t) => t.id.isIn(ids))).write(
      LocalTicketsCompanion(
        printed: const Value(true),
        printedAt: Value(when),
      ),
    );
  }

  Future<LocalTicket?> getTicketById(String id) =>
      (select(localTickets)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Sync queue ───────────────────────────────────────────────────

  Future<int> enqueueSync(SyncQueueItemsCompanion item) =>
      into(syncQueueItems).insert(item);

  Future<List<SyncQueueItem>> getPendingSyncItems() => (select(syncQueueItems)
        ..where((q) => q.status.isIn(['pending', 'failed']))
        ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
      .get();

  Future<int> countPendingSyncItems() async {
    final count = countAll();
    final query = selectOnly(syncQueueItems)
      ..addColumns([count])
      ..where(syncQueueItems.status.isIn(['pending', 'failed', 'syncing']));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> updateSyncItem(
    int id, {
    required String status,
    String? error,
    int? retryCount,
  }) {
    return (update(syncQueueItems)..where((q) => q.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: Value(status),
        lastError: error != null ? Value(error) : const Value.absent(),
        retryCount:
            retryCount != null ? Value(retryCount) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getSyncMeta(String key) async {
    final row = await (select(syncMetadata)
          ..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSyncMeta(String key, String value) =>
      into(syncMetadata).insertOnConflictUpdate(
        SyncMetadataCompanion(key: Value(key), value: Value(value)),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'countryboy_conductor.db'));
    return NativeDatabase.createInBackground(file);
  });
}
