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
      await _applyPulledTrips(data['trips'] as List<dynamic>?);
      await _applyPulledTickets(data['tickets'] as List<dynamic>?);
      await _reconcileActiveTripFromServer();
    } catch (_) {
      // Reference pull is best-effort; direct fetches still work when authenticated.
    }
  }

  /// Upsert this conductor's trips from depot pull so peer-device tickets have context.
  Future<void> _applyPulledTrips(List<dynamic>? trips) async {
    if (trips == null || trips.isEmpty) return;

    final agent = await _storage.getAgentProfile();
    final agentId = agent?['id']?.toString();
    final depotId = await _storage.getDepotId();
    if (agentId == null || agentId.isEmpty || depotId == null) return;

    final fleets = await _db.getCachedFleets();
    final fleetById = {for (final f in fleets) f.id: f};
    final drivers = await _db.getCachedDrivers();
    final driverById = {for (final d in drivers) d.id: d};

    for (final raw in trips) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      if (json['agent_id']?.toString() != agentId) continue;

      final tripId = json['id']?.toString();
      if (tripId == null || tripId.isEmpty) continue;

      final fleetId = json['fleet_id']?.toString();
      if (fleetId == null || fleetId.isEmpty) continue;

      final startedRaw = json['started_at']?.toString();
      if (startedRaw == null || startedRaw.isEmpty) continue;
      final startedAt = DateTime.tryParse(startedRaw);
      if (startedAt == null) continue;

      DateTime? endedAt;
      final endedRaw = json['ended_at']?.toString();
      if (endedRaw != null && endedRaw.isNotEmpty) {
        endedAt = DateTime.tryParse(endedRaw);
      }

      final status = (json['status'] as String?) ?? 'ACTIVE';
      final fleet = fleetById[fleetId];
      final driverId = json['driver_id']?.toString();
      final driver = driverId == null ? null : driverById[driverId];

      await _db.upsertTrip(
        LocalTripsCompanion.insert(
          id: tripId,
          agentId: agentId,
          fleetId: fleetId,
          routeId: Value(json['route_id'] as String?),
          deviceId: Value(json['device_id'] as String?),
          depotId: depotId,
          status: Value(status),
          startedAt: startedAt,
          endedAt: Value(endedAt),
          fleetNumber: Value(fleet?.number),
          fleetRegistrationNumber: Value(fleet?.registrationNumber),
          driverId: Value(driverId),
          driverName: Value(driver?.fullName),
          routeOrigin: Value(json['origin'] as String?),
          routeDestination: Value(json['destination'] as String?),
          syncStatus: const Value('synced'),
        ),
      );

      if (status != 'ACTIVE') {
        await _db.markTripEnded(
          tripId,
          status: status == 'COMPLETED' ? 'COMPLETED' : 'ENDED',
          endedAt: endedAt,
        );
      }
    }
  }

  /// Merge this conductor's tickets from other devices into local Sales & Tickets.
  Future<void> _applyPulledTickets(List<dynamic>? tickets) async {
    if (tickets == null || tickets.isEmpty) return;

    final agent = await _storage.getAgentProfile();
    final agentId = agent?['id']?.toString();
    final depotId = await _storage.getDepotId();
    if (agentId == null || agentId.isEmpty || depotId == null) return;

    for (final raw in tickets) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      if (json['agent_id']?.toString() != agentId) continue;

      final id = json['id']?.toString();
      final tripId = json['trip_id']?.toString();
      if (id == null || id.isEmpty || tripId == null || tripId.isEmpty) {
        continue;
      }

      final amount = _parseAmount(json['amount']);
      if (amount == null) continue;

      final issuedRaw = json['issued_at']?.toString();
      final issuedAt = issuedRaw == null || issuedRaw.isEmpty
          ? null
          : DateTime.tryParse(issuedRaw);
      if (issuedAt == null) continue;

      final existing = await _db.getTicketById(id);
      // Don't clobber an unsynced local issue still waiting to push.
      if (existing != null && existing.syncStatus != 'synced') {
        if (json['printed'] == true && !existing.printed) {
          DateTime? printedAt;
          final printedRaw = json['printed_at']?.toString();
          if (printedRaw != null && printedRaw.isNotEmpty) {
            printedAt = DateTime.tryParse(printedRaw);
          }
          await _db.markTicketsPrinted([id], printedAt: printedAt);
        }
        continue;
      }

      DateTime? printedAt;
      final printedRaw = json['printed_at']?.toString();
      if (printedRaw != null && printedRaw.isNotEmpty) {
        printedAt = DateTime.tryParse(printedRaw);
      }

      final luggageAmount = _parseAmount(json['luggage_amount']);
      final currency = (json['currency'] as String?) ?? 'USD';
      final category = (json['ticket_category'] as String?) ?? 'PASSENGER';

      await _db.upsertTicket(
        LocalTicketsCompanion.insert(
          id: id,
          tripId: tripId,
          agentId: agentId,
          deviceId: Value(json['device_id'] as String?),
          depotId: (json['depot_id'] as String?) ?? depotId,
          ticketCategory: category,
          currency: currency,
          amount: amount,
          departure: Value(json['departure'] as String?),
          destination: Value(json['destination'] as String?),
          passengerName: Value(json['passenger_name'] as String?),
          passengerPhone: Value(json['passenger_phone'] as String?),
          luggageAmount: Value(luggageAmount),
          luggageDescription: Value(json['luggage_description'] as String?),
          serialNumber: Value(json['serial_number'] as int?),
          issuedAt: issuedAt,
          printed: Value(json['printed'] == true),
          printedAt: Value(printedAt),
          syncStatus: const Value('synced'),
          idempotencyKey: existing?.idempotencyKey ?? 'pull:$id',
        ),
      );
    }
  }

  double? _parseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
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

      // Ensure peer devices import the shared active trip shell.
      final depotId = await _storage.getDepotId();
      if (depotId == null) return;
      final fleet = remote['fleet'] as Map<String, dynamic>?;
      final driver = remote['driver'] as Map<String, dynamic>?;
      final route = remote['route'] as Map<String, dynamic>?;
      final origin =
          (remote['origin'] as String?) ?? (route?['origin'] as String?);
      final destination = (remote['destination'] as String?) ??
          (route?['destination'] as String?);
      await _db.upsertTrip(
        LocalTripsCompanion.insert(
          id: remoteId,
          agentId: agentId,
          fleetId: remote['fleet_id'] as String,
          routeId: Value(remote['route_id'] as String?),
          deviceId: Value(remote['device_id'] as String?),
          depotId: depotId,
          status: const Value('ACTIVE'),
          startedAt: DateTime.parse(remote['started_at'] as String),
          fleetNumber: Value(fleet?['number'] as String?),
          fleetRegistrationNumber: Value(
            fleet?['registration_number'] as String?,
          ),
          driverId: Value(
            remote['driver_id'] as String? ?? driver?['id'] as String?,
          ),
          driverName: Value(driver?['full_name'] as String?),
          routeOrigin: Value(origin),
          routeDestination: Value(destination),
          syncStatus: const Value('synced'),
        ),
      );
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
      final startingMileage = (payload['starting_mileage'] as num?)?.toInt() ??
          localTrip?.startingMileage;
      final waybillNo =
          payload['waybill_no'] as String? ?? localTrip?.waybillNo;
      if (startingMileage == null) {
        throw ApiError(
          message: 'Starting mileage is required before syncing this trip.',
        );
      }
      if (waybillNo == null || waybillNo.isEmpty) {
        throw ApiError(
          message: 'Waybill number is required before syncing this trip.',
        );
      }

      final response = await _tripApi.startTrip(
        tripId: localTripId,
        fleetId: payload['fleet_id'] as String? ?? localTrip?.fleetId ?? '',
        origin: origin,
        destination: destination,
        routeId: payload['route_id'] as String? ?? localTrip?.routeId,
        driverId: payload['driver_id'] as String? ?? localTrip?.driverId,
        deviceId: payload['device_id'] as String? ?? localTrip?.deviceId,
        startedOffline: payload['started_offline'] as bool? ?? true,
        startingMileage: startingMileage,
        waybillNo: waybillNo,
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
      if (trip.startingMileage != null)
        'starting_mileage': trip.startingMileage,
      if (trip.waybillNo != null) 'waybill_no': trip.waybillNo,
      if (trip.closingMileage != null)
        'closing_mileage': trip.closingMileage,
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
