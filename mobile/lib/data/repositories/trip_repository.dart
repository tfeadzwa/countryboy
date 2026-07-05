import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/models/models.dart';
import '../../services/sync_service.dart';
import '../api/api_services.dart';
import '../local/database.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    api: ref.watch(tripApiProvider),
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

class TripRepository {
  TripRepository({
    required TripApi api,
    required AppDatabase db,
    required SecureStorageService storage,
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _api = api,
        _db = db,
        _storage = storage,
        _connectivity = connectivity,
        _sync = syncService;

  final TripApi _api;
  final AppDatabase _db;
  final SecureStorageService _storage;
  final ConnectivityService _connectivity;
  final SyncService _sync;

  Future<TripModel?> getActiveTrip() async {
    final agent = await _storage.getAgentProfile();
    if (agent == null) return null;

    final local = await _db.getActiveTrip(agent['id'] as String);
    if (local != null) {
      final stats = await _loadTripStats(local.id);
      return _mapLocalTrip(local).copyWith(
        ticketsCount: stats.count,
        totalRevenue: stats.revenue,
      );
    }

    if (await _connectivity.checkReachability()) {
      try {
        final remote = await _api.getActiveTrip();
        if (remote == null) return null;
        await _saveRemoteTripToLocal(remote);
        return _mapRemoteTrip(remote);
      } catch (_) {}
    }
    return null;
  }

  /// Pulls the server's active trip into local storage after sign-in.
  Future<void> syncActiveTripFromServer() async {
    if (!await _connectivity.checkReachability()) return;
    try {
      final remote = await _api.getActiveTrip();
      if (remote != null) {
        await _saveRemoteTripToLocal(remote);
      }
    } catch (_) {}
  }

  Future<TripModel?> getTripById(String id) async {
    final local = await _db.getTripById(id);
    if (local != null) {
      final stats = await _loadTripStats(local.id);
      return _mapLocalTrip(local).copyWith(
        ticketsCount: stats.count,
        totalRevenue: stats.revenue,
      );
    }
    return null;
  }

  Future<({int count, double revenue})> _loadTripStats(String tripId) async {
    final tickets = await _db.getAllTickets(tripId: tripId);
    final revenue = tickets.fold<double>(0, (sum, t) => sum + t.amount);
    return (count: tickets.length, revenue: revenue);
  }

  Future<TripModel> startTrip({
    required String fleetId,
    required String routeId,
    required String fleetNumber,
    required String routeOrigin,
    required String routeDestination,
  }) async {
    final agentJson = await _storage.getAgentProfile();
    final depotId = await _storage.getDepotId();
    final deviceId = await _storage.getDeviceId();
    if (agentJson == null || depotId == null) {
      throw ApiError(message: 'Session expired. Please sign in again.');
    }
    final agentId = agentJson['id'] as String;

    final existing = await _db.getActiveTrip(agentId);
    if (existing != null) {
      throw ApiError(message: 'You already have an active trip. End it first.');
    }

    final offline = !(await _connectivity.checkReachability());

    if (!offline) {
      final serverActive = await _fetchServerActiveTrip();
      if (serverActive != null) {
        await _saveRemoteTripToLocal(serverActive);
        throw ApiError(
          message:
              'You already have an active trip on the server. End it before starting a new one.',
        );
      }
    }

    final tripId = _sync.generateId();
    final startedAt = DateTime.now();

    await _db.upsertTrip(
      LocalTripsCompanion.insert(
        id: tripId,
        agentId: agentId,
        fleetId: fleetId,
        routeId: routeId,
        deviceId: Value(deviceId),
        depotId: depotId,
        status: const Value('ACTIVE'),
        startedOffline: Value(offline),
        startedAt: startedAt,
        fleetNumber: Value(fleetNumber),
        routeOrigin: Value(routeOrigin),
        routeDestination: Value(routeDestination),
        syncStatus: Value(offline ? 'pending' : 'syncing'),
      ),
    );

    if (offline) {
      await _db.enqueueSync(
        SyncQueueItemsCompanion.insert(
          entityType: 'trip',
          entityId: tripId,
          operation: 'CREATE_TRIP',
          payloadJson: jsonEncode({
            'id': tripId,
            'fleet_id': fleetId,
            'route_id': routeId,
            'device_id': deviceId,
            'started_offline': true,
          }),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return TripModel(
        id: tripId,
        agentId: agentId,
        fleetId: fleetId,
        routeId: routeId,
        deviceId: deviceId,
        status: 'ACTIVE',
        startedAt: startedAt,
        fleetNumber: fleetNumber,
        routeOrigin: routeOrigin,
        routeDestination: routeDestination,
        syncStatus: 'pending',
      );
    }

    try {
      final response = await _api.startTrip(
        tripId: tripId,
        fleetId: fleetId,
        routeId: routeId,
        deviceId: deviceId,
        startedOffline: false,
      );
      final trip = response['trip'] as Map<String, dynamic>;
      final serverId = trip['id'] as String;

      await _db.upsertTrip(
        LocalTripsCompanion.insert(
          id: serverId,
          agentId: agentId,
          fleetId: fleetId,
          routeId: routeId,
          deviceId: Value(deviceId),
          depotId: depotId,
          status: const Value('ACTIVE'),
          startedAt: startedAt,
          fleetNumber: Value(fleetNumber),
          routeOrigin: Value(routeOrigin),
          routeDestination: Value(routeDestination),
          syncStatus: const Value('synced'),
        ),
      );

      if (serverId != tripId) {
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId))).go();
      }

      return _mapRemoteTrip(trip);
    } catch (e) {
      final apiError = asApiError(e);
      if (apiError?.statusCode == 409) {
        final serverActive = await _fetchServerActiveTrip();
        if (serverActive != null) {
          final serverId = serverActive['id'] as String;
          if (serverId == tripId) {
            await _saveRemoteTripToLocal(serverActive);
            return _mapRemoteTrip(serverActive);
          }
          await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId)))
              .go();
          await _saveRemoteTripToLocal(serverActive);
          throw ApiError(
            message:
                'You already have an active trip on the server. End it before starting a new one.',
          );
        }
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId)))
            .go();
        throw apiError!;
      }

      if (apiError != null) {
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId)))
            .go();
        throw apiError;
      }

      await _db.updateTripSyncStatus(tripId, 'pending');
      await _db.enqueueSync(
        SyncQueueItemsCompanion.insert(
          entityType: 'trip',
          entityId: tripId,
          operation: 'CREATE_TRIP',
          payloadJson: jsonEncode({
            'id': tripId,
            'fleet_id': fleetId,
            'route_id': routeId,
            'device_id': deviceId,
            'started_offline': true,
          }),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return TripModel(
        id: tripId,
        agentId: agentId,
        fleetId: fleetId,
        routeId: routeId,
        deviceId: deviceId,
        status: 'ACTIVE',
        startedAt: startedAt,
        fleetNumber: fleetNumber,
        routeOrigin: routeOrigin,
        routeDestination: routeDestination,
        syncStatus: 'pending',
      );
    }
  }

  Future<void> syncTripToServer(Map<String, dynamic> payload) async {
    await _api.startTrip(
      tripId: payload['id'] as String,
      fleetId: payload['fleet_id'] as String,
      routeId: payload['route_id'] as String,
      deviceId: payload['device_id'] as String?,
      startedOffline: payload['started_offline'] as bool? ?? true,
    );
    await _db.updateTripSyncStatus(payload['id'] as String, 'synced');
  }

  Future<TripEndSummary> endTrip(String tripId) async {
    final trip = await _db.getTripById(tripId);
    if (trip == null) throw ApiError(message: 'Trip not found.');

    final tickets = await _db.getAllTickets(tripId: tripId);
    final localTicketCount = tickets.length;
    final localRevenue = tickets.fold<double>(0, (sum, t) => sum + t.amount);
    final currency = tickets.isNotEmpty ? tickets.first.currency : 'USD';

    await _db.completeTrip(tripId);
    final endedAt = DateTime.now();

    var syncStatus = 'synced';
    var totalTickets = localTicketCount;
    var totalRevenue = localRevenue;

    if (await _connectivity.checkReachability()) {
      try {
        final response = await _api.endTrip(tripId);
        final result = response['trip'] as Map<String, dynamic>;
        totalTickets = result['total_tickets'] as int? ?? localTicketCount;
        totalRevenue =
            (result['total_revenue'] as num?)?.toDouble() ?? localRevenue;
        await _db.updateTripSyncStatus(tripId, 'synced');
      } catch (_) {
        syncStatus = 'pending';
        await _enqueueEndTrip(tripId);
      }
    } else {
      syncStatus = 'pending';
      await _enqueueEndTrip(tripId);
    }

    final routeLabel = trip.routeOrigin != null && trip.routeDestination != null
        ? '${trip.routeOrigin} → ${trip.routeDestination}'
        : 'Route';

    return TripEndSummary(
      tripId: tripId,
      routeLabel: routeLabel,
      fleetNumber: trip.fleetNumber ?? '—',
      startedAt: trip.startedAt,
      endedAt: endedAt,
      totalTickets: totalTickets,
      totalRevenue: totalRevenue,
      currency: currency,
      syncStatus: syncStatus,
    );
  }

  Future<void> endTripOnServer(String tripId) async {
    await _api.endTrip(tripId);
  }

  Future<void> _enqueueEndTrip(String tripId) async {
    await _db.updateTripSyncStatus(tripId, 'pending');
    await _db.enqueueSync(
      SyncQueueItemsCompanion.insert(
        entityType: 'trip',
        entityId: tripId,
        operation: 'END_TRIP',
        payloadJson: jsonEncode({'id': tripId}),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchServerActiveTrip() async {
    try {
      return await _api.getActiveTrip();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveRemoteTripToLocal(Map<String, dynamic> json) async {
    final depotId = await _storage.getDepotId();
    if (depotId == null) return;

    final fleet = json['fleet'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;

    await _db.upsertTrip(
      LocalTripsCompanion.insert(
        id: json['id'] as String,
        agentId: json['agent_id'] as String,
        fleetId: json['fleet_id'] as String,
        routeId: json['route_id'] as String? ?? '',
        deviceId: Value(json['device_id'] as String?),
        depotId: depotId,
        status: Value(json['status'] as String? ?? 'ACTIVE'),
        startedAt: DateTime.parse(json['started_at'] as String),
        fleetNumber: Value(fleet?['number'] as String?),
        routeOrigin: Value(route?['origin'] as String?),
        routeDestination: Value(route?['destination'] as String?),
        syncStatus: const Value('synced'),
      ),
    );
  }

  TripModel _mapLocalTrip(LocalTrip t) => TripModel(
        id: t.id,
        agentId: t.agentId,
        fleetId: t.fleetId,
        routeId: t.routeId,
        deviceId: t.deviceId,
        status: t.status,
        startedAt: t.startedAt,
        fleetNumber: t.fleetNumber,
        routeOrigin: t.routeOrigin,
        routeDestination: t.routeDestination,
        syncStatus: t.syncStatus,
      );

  TripModel _mapRemoteTrip(Map<String, dynamic> json) {
    final fleet = json['fleet'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;
    return TripModel(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      fleetId: json['fleet_id'] as String,
      routeId: json['route_id'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      startedAt: DateTime.parse(json['started_at'] as String),
      fleetNumber: fleet?['number'] as String?,
      routeOrigin: route?['origin'] as String?,
      routeDestination: route?['destination'] as String?,
      ticketsCount: json['tickets_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      syncStatus: 'synced',
    );
  }
}
