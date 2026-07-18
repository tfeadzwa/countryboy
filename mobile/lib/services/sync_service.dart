import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/secure_storage_service.dart';
import '../data/api/api_services.dart';
import '../data/local/database.dart';
import '../data/repositories/reference_repository.dart';
const _uuid = Uuid();

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    syncApi: ref.watch(syncApiProvider),
    tripApi: ref.watch(tripApiProvider),
    storage: ref.watch(secureStorageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    referenceRepository: ref.watch(referenceRepositoryProvider),
  );
});

class SyncService {
  SyncService({
    required AppDatabase db,
    required SyncApi syncApi,
    required TripApi tripApi,
    required SecureStorageService storage,
    required ConnectivityService connectivity,
    required ReferenceRepository referenceRepository,
  })  : _db = db,
        _syncApi = syncApi,
        _tripApi = tripApi,
        _storage = storage,
        _connectivity = connectivity,
        _referenceRepository = referenceRepository;

  final AppDatabase _db;
  final SyncApi _syncApi;
  final TripApi _tripApi;
  final SecureStorageService _storage;
  final ConnectivityService _connectivity;
  final ReferenceRepository _referenceRepository;

  bool _running = false;

  Future<void> syncIfOnline({bool force = false}) async {
    if (_running && !force) return;
    final reachable = await _connectivity.checkReachability();
    if (!reachable) return;
    if (!await _storage.hasOnlineAuth()) return;

    _running = true;
    _connectivity.setSyncing(true);
    try {
      await _pullReferenceData();
      await _processTripQueue();
      await _pushPendingTrips();
      await _ensureTripsForPendingTickets();
      await _processTicketQueue();
      await _db.setSyncMeta('last_sync_at', DateTime.now().toIso8601String());
    } finally {
      _running = false;
      _connectivity.setSyncing(false);
    }
  }

  Future<void> _pullReferenceData() async {
    try {
      final since = await _db.getSyncMeta('last_sync_at');
      final data = await _syncApi.pull(since: since);
      await _referenceRepository.cacheFromPullSnapshot(data);
    } catch (_) {
      // Reference pull is best-effort; direct fetches still work when authenticated.
    }
  }

  Future<void> _processTripQueue() async {
    final items = await _db.getPendingSyncItems();
    final tripItems = items.where(
      (item) => item.operation == 'CREATE_TRIP' || item.operation == 'END_TRIP',
    );

    for (final item in tripItems) {
      if (item.retryCount >= 5) continue;
      await _db.updateSyncItem(item.id, status: 'syncing');
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        switch (item.operation) {
          case 'CREATE_TRIP':
            await _syncCreateTrip(item, payload);
          case 'END_TRIP':
            await _tripApi.endTrip(item.entityId);
            await _db.updateTripSyncStatus(item.entityId, 'synced');
            await _db.updateSyncItem(item.id, status: 'synced');
          default:
            break;
        }
      } catch (e) {
        await _db.updateSyncItem(
          item.id,
          status: 'failed',
          error: e is ApiError ? e.message : 'Sync failed',
          retryCount: item.retryCount + 1,
        );
      }
    }
  }

  Future<void> _syncCreateTrip(
    SyncQueueItem item,
    Map<String, dynamic> payload,
  ) async {
    final localTripId = payload['id'] as String;

    try {
      await _tripApi.startTrip(
        tripId: localTripId,
        fleetId: payload['fleet_id'] as String,
        routeId: payload['route_id'] as String,
        deviceId: payload['device_id'] as String?,
        startedOffline: payload['started_offline'] as bool? ?? true,
      );
    } on ApiError catch (e) {
      if (e.statusCode == 409) {
        final active = await _tripApi.getActiveTrip();
        if (active != null && active['id'] == localTripId) {
          await _db.updateTripSyncStatus(localTripId, 'synced');
          await _db.updateSyncItem(item.id, status: 'synced');
          return;
        }
        await _db.updateSyncItem(
          item.id,
          status: 'failed',
          error:
              'An active trip already exists on the server. End it before starting a new one.',
          retryCount: item.retryCount + 1,
        );
        return;
      }
      rethrow;
    }

    await _db.updateTripSyncStatus(localTripId, 'synced');
    await _db.updateSyncItem(item.id, status: 'synced');
  }

  Future<void> _processTicketQueue() async {
    final items = await _db.getPendingSyncItems();
    final ticketItems =
        items.where((item) => item.operation == 'CREATE_TICKET');

    for (final item in ticketItems) {
      if (item.retryCount >= 5) continue;
      await _db.updateSyncItem(item.id, status: 'syncing');
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final tripId = payload['trip_id'] as String;
        await _ensureTripOnServer(tripId);

        final pushResult = await _syncApi.push(tickets: [payload]);
        final syncedTickets = pushResult['tickets'] as List<dynamic>? ?? [];
        final synced = syncedTickets.isNotEmpty
            ? syncedTickets.first as Map<String, dynamic>
            : payload;
        await _db.updateTicketSyncStatus(
          payload['id'] as String,
          'synced',
          serialNumber: synced['serial_number'] as int?,
        );
        await _db.updateSyncItem(item.id, status: 'synced');
      } catch (e) {
        await _db.updateSyncItem(
          item.id,
          status: 'failed',
          error: e is ApiError ? e.message : 'Sync failed',
          retryCount: item.retryCount + 1,
        );
      }
    }
  }

  /// Upserts trips referenced by pending tickets — fixes stale "synced" trips
  /// from older builds that never created the server row with the client id.
  Future<void> _ensureTripsForPendingTickets() async {
    final items = await _db.getPendingSyncItems();
    final tripIds = <String>{};

    for (final item in items) {
      if (item.operation != 'CREATE_TICKET') continue;
      final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
      tripIds.add(payload['trip_id'] as String);
    }

    for (final tripId in tripIds) {
      await _ensureTripOnServer(tripId);
    }
  }

  Future<void> _ensureTripOnServer(String tripId) async {
    final trip = await _db.getTripById(tripId);
    if (trip == null) {
      throw ApiError(message: 'Trip not found on device.');
    }

    await _syncApi.push(trips: [_tripPayload(trip)]);
    await _db.updateTripSyncStatus(tripId, 'synced');
  }

  Map<String, dynamic> _tripPayload(LocalTrip trip) => {
        'id': trip.id,
        'depot_id': trip.depotId,
        'agent_id': trip.agentId,
        'fleet_id': trip.fleetId,
        'route_id': trip.routeId,
        'device_id': trip.deviceId,
        'started_at': trip.startedAt.toUtc().toIso8601String(),
        'status': trip.status,
        'started_offline': trip.startedOffline,
        if (trip.endedAt != null)
          'ended_at': trip.endedAt!.toUtc().toIso8601String(),
      };

  Future<void> _pushPendingTrips() async {
    final agent = await _storage.getAgentProfile();
    final depotId = await _storage.getDepotId();
    if (agent == null || depotId == null) return;

    final pendingTrips = await (_db.select(_db.localTrips)
          ..where((t) => t.syncStatus.isNotIn(['synced'])))
        .get();

    if (pendingTrips.isEmpty) return;

    final tripPayloads = pendingTrips.map(_tripPayload).toList();

    final result = await _syncApi.push(trips: tripPayloads);

    for (final trip in result['trips'] as List<dynamic>? ?? []) {
      final id = trip['id'] as String;
      await _db.updateTripSyncStatus(id, 'synced');
    }
  }

  Future<void> retryItem(int queueId) async {
    await _db.updateSyncItem(queueId, status: 'pending', error: null, retryCount: 0);
    await syncIfOnline(force: true);
  }

  Future<void> retryAll() async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      await _db.updateSyncItem(
        item.id,
        status: 'pending',
        error: null,
        retryCount: 0,
      );
      if (item.operation == 'CREATE_TICKET') {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        await _db.updateTripSyncStatus(payload['trip_id'] as String, 'pending');
      }
    }
    await syncIfOnline(force: true);
  }

  Future<int> pendingCount() => _db.countPendingSyncItems();

  Future<DateTime?> lastSyncAt() async {
    final raw = await _db.getSyncMeta('last_sync_at');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  String generateId() => _uuid.v4();
}
