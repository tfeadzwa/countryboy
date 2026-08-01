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
    try {
      final agent = await _storage.getAgentProfile();
      if (agent == null) return null;

      final agentId = agent['id']?.toString();
      if (agentId == null || agentId.isEmpty) return null;

      // When online, prefer server truth so cashier/admin end closes local issue flow.
      if (await _connectivity.checkReachability() &&
          await _storage.hasOnlineAuth()) {
        await reconcileActiveTripFromServer();
      }

      final local = await _db.getActiveTrip(agentId);
      if (local != null) {
        final stats = await _loadTripStats(local.id);
        return _mapLocalTrip(local).copyWith(
          ticketsCount: stats.count,
          totalRevenue: stats.revenue,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Aligns local ACTIVE trip with `/agents/trips/active`.
  /// Clears local ACTIVE when the cashier/admin has ended the trip on the server.
  Future<void> reconcileActiveTripFromServer() async {
    if (!await _connectivity.checkReachability() ||
        !await _storage.hasOnlineAuth()) {
      return;
    }

    final agent = await _storage.getAgentProfile();
    final agentId = agent?['id']?.toString();
    if (agentId == null || agentId.isEmpty) return;

    try {
      final remote = await _api.getActiveTrip();
      if (remote == null) {
        await _db.markAgentActiveTripsEnded(agentId);
        return;
      }

      final remoteStatus = (remote['status'] as String?) ?? 'ACTIVE';
      if (remoteStatus != 'ACTIVE') {
        await _saveRemoteTripToLocal(remote);
        await _db.markAgentActiveTripsEnded(agentId);
        return;
      }

      final remoteId = remote['id'] as String;
      final localActive = await _db.getActiveTrip(agentId);
      if (localActive != null && localActive.id != remoteId) {
        await _db.markTripEnded(localActive.id);
      }
      await _saveRemoteTripToLocal(remote);
    } catch (_) {
      // Keep local trip if reconcile fails (offline blip / auth).
    }
  }

  /// Pulls the server's active trip into local storage after sign-in.
  Future<void> syncActiveTripFromServer() => reconcileActiveTripFromServer();

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
    required String fleetNumber,
    String? fleetRegistrationNumber,
    required String driverId,
    required String driverName,
    required String origin,
    required String destination,
    required int startingMileage,
    required String waybillNo,
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

    final offline = !(await _connectivity.checkReachability()) ||
        !(await _storage.hasOnlineAuth());

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
        routeId: const Value(null),
        deviceId: Value(deviceId),
        depotId: depotId,
        status: const Value('ACTIVE'),
        startedOffline: Value(offline),
        startedAt: startedAt,
        fleetNumber: Value(fleetNumber),
        fleetRegistrationNumber: Value(fleetRegistrationNumber),
        driverId: Value(driverId),
        driverName: Value(driverName),
        routeOrigin: Value(origin),
        routeDestination: Value(destination),
        startingMileage: Value(startingMileage),
        waybillNo: Value(waybillNo),
        syncStatus: Value(offline ? 'pending' : 'syncing'),
      ),
    );

    await _db.setFleetOnTrip(fleetId, true);
    await _db.setDriverOnTrip(driverId, true);

    final syncPayload = {
      'id': tripId,
      'fleet_id': fleetId,
      'driver_id': driverId,
      'origin': origin,
      'destination': destination,
      'device_id': deviceId,
      'started_offline': true,
      'started_at': startedAt.toUtc().toIso8601String(),
      'agent_id': agentId,
      'status': 'ACTIVE',
      'starting_mileage': startingMileage,
      'waybill_no': waybillNo,
    };

    if (offline) {
      await _db.enqueueSync(
        SyncQueueItemsCompanion.insert(
          entityType: 'trip',
          entityId: tripId,
          operation: 'CREATE_TRIP',
          payloadJson: jsonEncode(syncPayload),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return TripModel(
        id: tripId,
        agentId: agentId,
        fleetId: fleetId,
        deviceId: deviceId,
        status: 'ACTIVE',
        startedAt: startedAt,
        fleetNumber: fleetNumber,
        fleetRegistrationNumber: fleetRegistrationNumber,
        driverId: driverId,
        driverName: driverName,
        routeOrigin: origin,
        routeDestination: destination,
        startingMileage: startingMileage,
        waybillNo: waybillNo,
        syncStatus: 'pending',
      );
    }

    try {
      final response = await _api.startTrip(
        tripId: tripId,
        fleetId: fleetId,
        driverId: driverId,
        origin: origin,
        destination: destination,
        deviceId: deviceId,
        startedOffline: false,
        startingMileage: startingMileage,
        waybillNo: waybillNo,
      );
      final trip = response['trip'] as Map<String, dynamic>;
      final serverId = trip['id'] as String;

      await _db.upsertTrip(
        LocalTripsCompanion.insert(
          id: serverId,
          agentId: agentId,
          fleetId: fleetId,
          routeId: Value(trip['route_id'] as String?),
          deviceId: Value(deviceId),
          depotId: depotId,
          status: const Value('ACTIVE'),
          startedAt: startedAt,
          fleetNumber: Value(fleetNumber),
          fleetRegistrationNumber: Value(fleetRegistrationNumber),
          driverId: Value(
            trip['driver_id'] as String? ?? driverId,
          ),
          driverName: Value(
            (trip['driver'] as Map?)?['full_name'] as String? ?? driverName,
          ),
          routeOrigin: Value(origin),
          routeDestination: Value(destination),
          startingMileage: Value(
            (trip['starting_mileage'] as num?)?.toInt() ?? startingMileage,
          ),
          waybillNo: Value(
            trip['waybill_no'] as String? ?? waybillNo,
          ),
          syncStatus: const Value('synced'),
        ),
      );

      if (serverId != tripId) {
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId))).go();
      }

      return _mapRemoteTrip(trip).copyWith(
        fleetRegistrationNumber: fleetRegistrationNumber,
      );
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
          await _db.setFleetOnTrip(fleetId, false);
          await _db.setDriverOnTrip(driverId, false);
          await _saveRemoteTripToLocal(serverActive);
          throw ApiError(
            message:
                'You already have an active trip on the server. End it before starting a new one.',
          );
        }
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId)))
            .go();
        await _db.setFleetOnTrip(fleetId, false);
        await _db.setDriverOnTrip(driverId, false);
        throw apiError!;
      }

      if (apiError != null) {
        await (_db.delete(_db.localTrips)..where((t) => t.id.equals(tripId)))
            .go();
        await _db.setFleetOnTrip(fleetId, false);
        await _db.setDriverOnTrip(driverId, false);
        throw apiError;
      }

      await _db.updateTripSyncStatus(tripId, 'pending');
      await _db.enqueueSync(
        SyncQueueItemsCompanion.insert(
          entityType: 'trip',
          entityId: tripId,
          operation: 'CREATE_TRIP',
          payloadJson: jsonEncode(syncPayload),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return TripModel(
        id: tripId,
        agentId: agentId,
        fleetId: fleetId,
        deviceId: deviceId,
        status: 'ACTIVE',
        startedAt: startedAt,
        fleetNumber: fleetNumber,
        fleetRegistrationNumber: fleetRegistrationNumber,
        driverId: driverId,
        driverName: driverName,
        routeOrigin: origin,
        routeDestination: destination,
        startingMileage: startingMileage,
        waybillNo: waybillNo,
        syncStatus: 'pending',
      );
    }
  }

  Future<void> syncTripToServer(Map<String, dynamic> payload) async {
    await _api.startTrip(
      tripId: payload['id'] as String,
      fleetId: payload['fleet_id'] as String,
      origin: payload['origin'] as String,
      destination: payload['destination'] as String,
      routeId: payload['route_id'] as String?,
      driverId: payload['driver_id'] as String?,
      deviceId: payload['device_id'] as String?,
      startedOffline: payload['started_offline'] as bool? ?? true,
      startingMileage: (payload['starting_mileage'] as num).toInt(),
      waybillNo: payload['waybill_no'] as String,
    );
    await _db.updateTripSyncStatus(payload['id'] as String, 'synced');
  }

  Future<TripEndSummary> endTrip(String tripId) async {
    throw ApiError(
      message:
          'Conductors cannot end trips. Ask the depot cashier to close this trip from the admin console.',
    );
  }

  Future<void> endTripOnServer(String tripId) async {
    throw ApiError(
      message:
          'Conductors cannot end trips. Ask the depot cashier to close this trip from the admin console.',
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
    final driver = json['driver'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;
    final origin =
        (json['origin'] as String?) ?? (route?['origin'] as String?);
    final destination =
        (json['destination'] as String?) ?? (route?['destination'] as String?);
    final endedRaw = json['ended_at'];
    DateTime? endedAt;
    if (endedRaw is String && endedRaw.isNotEmpty) {
      endedAt = DateTime.tryParse(endedRaw);
    }

    await _db.upsertTrip(
      LocalTripsCompanion.insert(
        id: json['id'] as String,
        agentId: json['agent_id'] as String,
        fleetId: json['fleet_id'] as String,
        routeId: Value(json['route_id'] as String?),
        deviceId: Value(json['device_id'] as String?),
        depotId: depotId,
        status: Value(json['status'] as String? ?? 'ACTIVE'),
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: Value(endedAt),
        fleetNumber: Value(fleet?['number'] as String?),
        fleetRegistrationNumber: Value(
          fleet?['registration_number'] as String?,
        ),
        driverId: Value(json['driver_id'] as String? ?? driver?['id'] as String?),
        driverName: Value(driver?['full_name'] as String?),
        routeOrigin: Value(origin),
        routeDestination: Value(destination),
        startingMileage: Value((json['starting_mileage'] as num?)?.toInt()),
        waybillNo: Value(json['waybill_no'] as String?),
        closingMileage: Value((json['closing_mileage'] as num?)?.toInt()),
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
        fleetRegistrationNumber: t.fleetRegistrationNumber,
        driverId: t.driverId,
        driverName: t.driverName,
        routeOrigin: t.routeOrigin,
        routeDestination: t.routeDestination,
        startingMileage: t.startingMileage,
        waybillNo: t.waybillNo,
        closingMileage: t.closingMileage,
        syncStatus: t.syncStatus.isEmpty ? 'pending' : t.syncStatus,
      );

  TripModel _mapRemoteTrip(Map<String, dynamic> json) {
    final fleet = json['fleet'] as Map<String, dynamic>?;
    final driver = json['driver'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;
    final origin =
        (json['origin'] as String?) ?? (route?['origin'] as String?);
    final destination =
        (json['destination'] as String?) ?? (route?['destination'] as String?);
    return TripModel(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      fleetId: json['fleet_id'] as String,
      routeId: json['route_id'] as String?,
      deviceId: json['device_id'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      startedAt: DateTime.parse(json['started_at'] as String),
      fleetNumber: fleet?['number'] as String? ?? json['fleet_number'] as String?,
      fleetRegistrationNumber: fleet?['registration_number'] as String? ??
          json['fleet_registration_number'] as String?,
      driverId: json['driver_id'] as String? ?? driver?['id'] as String?,
      driverName: driver?['full_name'] as String?,
      routeOrigin: origin,
      routeDestination: destination,
      startingMileage: (json['starting_mileage'] as num?)?.toInt(),
      waybillNo: json['waybill_no'] as String?,
      closingMileage: (json['closing_mileage'] as num?)?.toInt(),
      ticketsCount: json['tickets_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      syncStatus: 'synced',
    );
  }
}
