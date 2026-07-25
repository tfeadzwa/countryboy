import 'dart:convert';

import 'package:drift/drift.dart';
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

  /// Lightweight probe used before issuing tickets while online.
  Future<void> reconcileActiveTrip() async {
    final reachable = await _connectivity.checkReachability();
    if (!reachable) return;
    if (!await _storage.hasOnlineAuth()) return;
    await _reconcileActiveTripFromServer();
  }

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
      await _applyPulledTripUpdates(data['trips'] as List<dynamic>?);
      await _applyPulledTicketPrintState(data['tickets'] as List<dynamic>?);
      await _reconcileActiveTripFromServer();
    } catch (_) {
      // Reference pull is best-effort; direct fetches still work when authenticated.
    }
  }

  /// Apply cashier/admin trip status changes from sync pull onto matching local rows.
  Future<void> _applyPulledTripUpdates(List<dynamic>? trips) async {
    if (trips == null || trips.isEmpty) return;

    final agent = await _storage.getAgentProfile();
    final agentId = agent?['id']?.toString();
    if (agentId == null || agentId.isEmpty) return;

    for (final raw in trips) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      if (json['agent_id']?.toString() != agentId) continue;

      final tripId = json['id']?.toString();
      if (tripId == null || tripId.isEmpty) continue;

      final local = await _db.getTripById(tripId);
      if (local == null) continue;

      final status = (json['status'] as String?) ?? local.status;
      if (status == 'ACTIVE') continue;

      DateTime? endedAt;
      final endedRaw = json['ended_at'];
      if (endedRaw is String && endedRaw.isNotEmpty) {
        endedAt = DateTime.tryParse(endedRaw);
      }

      await _db.markTripEnded(
        tripId,
        status: status == 'COMPLETED' ? 'COMPLETED' : 'ENDED',
        endedAt: endedAt,
      );
    }
  }

  Future<void> _applyPulledTicketPrintState(List<dynamic>? tickets) async {
    if (tickets == null || tickets.isEmpty) return;

    final printedIds = <String>[];
    DateTime? latestPrintedAt;

    for (final raw in tickets) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      if (json['printed'] != true) continue;
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final local = await _db.getTicketById(id);
      if (local == null || local.printed) continue;
      printedIds.add(id);
      final rawAt = json['printed_at'];
      if (rawAt is String && rawAt.isNotEmpty) {
        latestPrintedAt = DateTime.tryParse(rawAt) ?? latestPrintedAt;
      }
    }

    if (printedIds.isNotEmpty) {
      await _db.markTicketsPrinted(printedIds, printedAt: latestPrintedAt);
    }
  }

  /// If the server has no ACTIVE trip for this agent, clear local ACTIVE rows.
  Future<void> _reconcileActiveTripFromServer() async {
    final agent = await _storage.getAgentProfile();
    final agentId = agent?['id']?.toString();
    if (agentId == null || agentId.isEmpty) return;

    try {
      final remote = await _tripApi.getActiveTrip();
      if (remote == null) {
        await _db.markAgentActiveTripsEnded(agentId);
        return;
      }

      final remoteStatus = (remote['status'] as String?) ?? 'ACTIVE';
      final remoteId = remote['id']?.toString();
      if (remoteStatus != 'ACTIVE' || remoteId == null) {
        await _db.markAgentActiveTripsEnded(agentId);
        return;
      }

      final localActive = await _db.getActiveTrip(agentId);
      if (localActive != null && localActive.id != remoteId) {
        await _db.markTripEnded(localActive.id);
      }
    } catch (_) {
      // Keep local state if active-trip probe fails.
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
            await _db.updateSyncItem(
              item.id,
              status: 'failed',
              error:
                  'Conductors cannot end trips. A cashier must close the trip in the admin console.',
              retryCount: item.retryCount + 1,
            );
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
    final localTrip = await _db.getTripById(localTripId);

    final origin = _resolveTripPlace(
      payload['origin'],
      localTrip?.routeOrigin,
    );
    final destination = _resolveTripPlace(
      payload['destination'],
      localTrip?.routeDestination,
    );

    if (origin.length < 2 || destination.length < 2) {
      throw ApiError(
        message:
            'Trip origin/destination are required before syncing. Re-enter the corridor and retry.',
      );
    }

    try {
      final response = await _tripApi.startTrip(
        tripId: localTripId,
        fleetId: payload['fleet_id'] as String? ?? localTrip?.fleetId ?? '',
        origin: origin,
        destination: destination,
        routeId: payload['route_id'] as String? ?? localTrip?.routeId,
        driverId: payload['driver_id'] as String? ?? localTrip?.driverId,
        deviceId: payload['device_id'] as String? ?? localTrip?.deviceId,
        startedOffline: payload['started_offline'] as bool? ?? true,
      );

      final serverTrip = response['trip'] as Map<String, dynamic>?;
      await _applySyncedTripFields(
        localTripId,
        routeId: serverTrip?['route_id'] as String?,
        origin: origin,
        destination: destination,
      );
    } on ApiError catch (e) {
      if (e.statusCode == 409) {
        final active = await _tripApi.getActiveTrip();
        if (active != null && active['id'] == localTripId) {
          await _applySyncedTripFields(
            localTripId,
            routeId: active['route_id'] as String?,
            origin: (active['origin'] as String?) ??
                (active['route'] as Map?)?['origin'] as String? ??
                origin,
            destination: (active['destination'] as String?) ??
                (active['route'] as Map?)?['destination'] as String? ??
                destination,
          );
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

    await _db.updateSyncItem(item.id, status: 'synced');
  }

  String _resolveTripPlace(dynamic payloadValue, String? localValue) {
    final fromPayload = payloadValue is String ? payloadValue.trim() : '';
    if (fromPayload.isNotEmpty) return fromPayload;
    return localValue?.trim() ?? '';
  }

  Future<void> _applySyncedTripFields(
    String tripId, {
    String? routeId,
    String? origin,
    String? destination,
  }) async {
    await (_db.update(_db.localTrips)..where((t) => t.id.equals(tripId))).write(
      LocalTripsCompanion(
        syncStatus: const Value('synced'),
        routeId: routeId != null ? Value(routeId) : const Value.absent(),
        routeOrigin:
            origin != null && origin.isNotEmpty ? Value(origin) : const Value.absent(),
        routeDestination: destination != null && destination.isNotEmpty
            ? Value(destination)
            : const Value.absent(),
      ),
    );
  }

  Future<void> _processTicketQueue() async {
    final items = await _db.getPendingSyncItems();
    final ticketItems = items.where(
      (item) =>
          item.operation == 'CREATE_TICKET' ||
          item.operation == 'MARK_TICKET_PRINTED',
    );

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
        if (item.operation == 'MARK_TICKET_PRINTED' ||
            synced['printed'] == true) {
          final printedAtRaw = synced['printed_at'] as String?;
          await _db.markTicketsPrinted(
            [payload['id'] as String],
            printedAt: printedAtRaw != null
                ? DateTime.tryParse(printedAtRaw)
                : null,
          );
        }
        await _db.updateSyncItem(item.id, status: 'synced');
      } catch (e) {
        final message = e is ApiError ? e.message : 'Sync failed';
        final closedTrip = message.toLowerCase().contains('trip is closed') ||
            message.toLowerCase().contains('trip was closed');
        if (closedTrip) {
          try {
            final payload =
                jsonDecode(item.payloadJson) as Map<String, dynamic>;
            final tripId = payload['trip_id'] as String?;
            if (tripId != null) {
              await _db.markTripEnded(tripId);
            }
          } catch (_) {}
        }
        await _db.updateSyncItem(
          item.id,
          status: 'failed',
          error: message,
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
      try {
        await _ensureTripOnServer(tripId);
      } catch (_) {
        // Ticket queue will retry ensure + surface the error per ticket.
      }
    }
  }

  Future<void> _ensureTripOnServer(String tripId) async {
    final trip = await _db.getTripById(tripId);
    if (trip == null) {
      throw ApiError(message: 'Trip not found on device.');
    }

    final origin = trip.routeOrigin?.trim() ?? '';
    final destination = trip.routeDestination?.trim() ?? '';
    if (origin.length < 2 || destination.length < 2) {
      throw ApiError(
        message:
            'Trip corridor is missing on device. End and restart the trip before syncing tickets.',
      );
    }

    final result = await _syncApi.push(trips: [_tripPayload(trip)]);
    Map<String, dynamic>? synced;
    for (final raw in result['trips'] as List<dynamic>? ?? []) {
      final row = raw as Map<String, dynamic>;
      if (row['id'] == tripId) {
        synced = row;
        break;
      }
    }
    synced ??= (result['trips'] as List?)?.isNotEmpty == true
        ? (result['trips'] as List).first as Map<String, dynamic>
        : null;

    await _applySyncedTripFields(
      tripId,
      routeId: synced?['route_id'] as String?,
      origin: origin,
      destination: destination,
    );
  }

  Map<String, dynamic> _tripPayload(LocalTrip trip) {
    final origin = trip.routeOrigin?.trim() ?? '';
    final destination = trip.routeDestination?.trim() ?? '';
    return {
      'id': trip.id,
      'depot_id': trip.depotId,
      'agent_id': trip.agentId,
      'fleet_id': trip.fleetId,
      if (trip.routeId != null) 'route_id': trip.routeId,
      if (trip.driverId != null) 'driver_id': trip.driverId,
      'origin': origin,
      'destination': destination,
      'device_id': trip.deviceId,
      'started_at': trip.startedAt.toUtc().toIso8601String(),
      'status': trip.status,
      'started_offline': trip.startedOffline,
      if (trip.endedAt != null)
        'ended_at': trip.endedAt!.toUtc().toIso8601String(),
    };
  }

  Future<void> _pushPendingTrips() async {
    final agent = await _storage.getAgentProfile();
    final depotId = await _storage.getDepotId();
    if (agent == null || depotId == null) return;

    final pendingTrips = await (_db.select(_db.localTrips)
          ..where((t) => t.syncStatus.isNotIn(['synced'])))
        .get();

    if (pendingTrips.isEmpty) return;

    // Skip trips that cannot form a parent corridor yet.
    final syncable = pendingTrips.where((trip) {
      final origin = trip.routeOrigin?.trim() ?? '';
      final destination = trip.routeDestination?.trim() ?? '';
      return origin.length >= 2 && destination.length >= 2;
    }).toList();

    if (syncable.isEmpty) return;

    final tripPayloads = syncable.map(_tripPayload).toList();
    final result = await _syncApi.push(trips: tripPayloads);

    for (final raw in result['trips'] as List<dynamic>? ?? []) {
      final trip = raw as Map<String, dynamic>;
      final id = trip['id'] as String;
      await _applySyncedTripFields(
        id,
        routeId: trip['route_id'] as String?,
        origin: trip['origin'] as String?,
        destination: trip['destination'] as String?,
      );
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
