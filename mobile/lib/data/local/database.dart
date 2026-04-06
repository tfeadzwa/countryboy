import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import '../dto/trip_dto.dart';

part 'database.g.dart';

/// Main database class for Countryboy Conductor app
@DriftDatabase(tables: [
  Devices,
  Agents,
  Routes,
  Fleets,
  Trips,
  Tickets,
  SyncQueue,
  CacheMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to >= 2) {
          // Migration from v1 to v2: Add Fleets and CacheMetadata tables
          await m.createTable(fleets);
          await m.createTable(cacheMetadata);
        }
        
        if (from <= 2 && to >= 3) {
          // Migration from v2 to v3: Recreate Fleets and Routes with serverId
          await m.deleteTable('fleets');
          await m.deleteTable('routes');
          await m.createTable(fleets);
          await m.createTable(routes);
        }
        
        if (from <= 3 && to >= 4) {
          // Migration from v3 to v4: Update Trips table for offline support
          await m.deleteTable('trips');
          await m.createTable(trips);
        }
        
        if (from <= 4 && to >= 5) {
          // Migration from v4 to v5: Update Tickets table for offline-first ticket issuing
          await m.deleteTable('tickets');
          await m.createTable(tickets);
        }
      },
    );
  }

  // Device operations
  Future<Device?> getActiveDevice() async {
    return (select(devices)..where((d) => d.isActive.equals(true)))
        .getSingleOrNull();
  }

  Future<int> insertDevice(DevicesCompanion device) async {
    // Deactivate all existing devices first
    await (update(devices)..where((d) => d.isActive.equals(true)))
        .write(const DevicesCompanion(isActive: Value(false)));

    // Insert new active device
    return into(devices).insert(device);
  }

  Future<bool> updateDevice(int id, DevicesCompanion device) async {
    return await (update(devices)..where((d) => d.id.equals(id))).write(device) > 0;
  }

  // Agent operations
  Future<Agent?> getAgentById(int id) async {
    return (select(agents)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<Agent?> getAgentByCode(String agentCode) async {
    return (select(agents)..where((a) => a.agentCode.equals(agentCode)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateAgent(AgentsCompanion agent) async {
    await into(agents).insertOnConflictUpdate(agent);
  }

  // Route operations
  Future<List<Route>> getAllActiveRoutes() async {
    return (select(routes)..where((r) => r.isActive.equals(true))).get();
  }

  Future<Route?> getRouteById(int id) async {
    return (select(routes)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertRoutes(List<RoutesCompanion> routeList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(routes, routeList);
    });
  }

  // Fleet operations
  Future<List<Fleet>> getAllActiveFleets() async {
    return (select(fleets)..where((f) => f.isActive.equals(true))).get();
  }

  Future<void> insertFleets(List<FleetsCompanion> fleetList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(fleets, fleetList);
    });
  }

  // Cache metadata operations
  Future<void> updateCacheMetadata(String dataType, int count) async {
    await into(cacheMetadata).insertOnConflictUpdate(
      CacheMetadataCompanion.insert(
        dataType: dataType,
        lastCachedAt: DateTime.now(),
        recordCount: Value(count),
      ),
    );
  }

  Future<DateTime?> getLastCacheTime(String dataType) async {
    final metadata = await (select(cacheMetadata)
      ..where((m) => m.dataType.equals(dataType))).getSingleOrNull();
    return metadata?.lastCachedAt;
  }

  Future<int> getCacheRecordCount(String dataType) async {
    final metadata = await (select(cacheMetadata)
      ..where((m) => m.dataType.equals(dataType))).getSingleOrNull();
    return metadata?.recordCount ?? 0;
  }

  // High-level cache operations for DTOs
  /// Cache fleets from API response
  Future<void> cacheFleets(List<FleetDto> fleetDtos) async {
    await transaction(() async {
      // Delete existing fleets to avoid conflicts
      await delete(fleets).go();
      
      // Insert new fleets
      final companions = fleetDtos.map((dto) => FleetsCompanion.insert(
        serverId: dto.id, // Store API ID as serverId
        number: dto.number,
        depotId: dto.depotId,
        cachedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
      
      await batch((batch) {
        batch.insertAll(fleets, companions);
      });
      
      await updateCacheMetadata('fleets', fleetDtos.length);
    });
  }

  /// Get cached fleets as DTOs
  Future<List<FleetDto>> getCachedFleets() async {
    final dbFleets = await getAllActiveFleets();
    return dbFleets.map((fleet) => FleetDto(
      id: fleet.serverId, // Map serverId back to DTO id
      number: fleet.number,
      depotId: fleet.depotId,
    )).toList();
  }

  /// Cache routes from API response
  Future<void> cacheRoutes(List<RouteDto> routeDtos) async {
    await transaction(() async {
      // Delete existing routes to avoid conflicts
      await delete(routes).go();
      
      // Insert new routes
      final companions = routeDtos.map((dto) => RoutesCompanion.insert(
        serverId: dto.id, // Store API ID as serverId
        routeCode: '${dto.origin}-${dto.destination}',
        routeName: '${dto.origin} to ${dto.destination}',
        origin: dto.origin,
        destination: dto.destination,
        fare: 0.0,
        distanceKm: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
      
      await batch((batch) {
        batch.insertAll(routes, companions);
      });
      
      await updateCacheMetadata('routes', routeDtos.length);
    });
  }

  /// Get cached routes as DTOs
  Future<List<RouteDto>> getCachedRoutes() async {
    final dbRoutes = await getAllActiveRoutes();
    return dbRoutes.map((route) => RouteDto(
      id: route.serverId, // Map serverId back to DTO id
      origin: route.origin,
      destination: route.destination,
      depotId: '', // Will be populated later
    )).toList();
  }

  // Trip operations
  /// Get active trips for a specific agent
  /// CRITICAL: Filters by agentId to ensure agent isolation on shared devices
  Future<List<Trip>> getActiveTrips(String agentId) async {
    return (select(trips)
          ..where((t) => 
              t.agentId.equals(agentId) &
              t.status.isIn(['scheduled', 'boarding', 'in_transit']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.departureTime, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<Trip?> getTripById(int id) async {
    return (select(trips)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdateTrip(TripsCompanion trip) async {
    await into(trips).insertOnConflictUpdate(trip);
  }

  Future<void> updateTripSeats(int tripId, int availableSeats) async {
    await (update(trips)..where((t) => t.id.equals(tripId)))
        .write(TripsCompanion(availableSeats: Value(availableSeats)));
  }

  /// Create a trip locally for offline operation
  Future<Trip> createTripLocally({
    required String localId,
    required String tripCode,
    required String routeId,
    required String fleetId,
    required String busNumber,
    required String driverName,
    required DateTime departureTime,
    required int totalSeats,
    required String status,
    required String agentId,
    required String agentCode,
  }) async {
    final companion = TripsCompanion.insert(
      localId: localId,
      tripCode: tripCode,
      routeId: routeId,
      fleetId: fleetId,
      busNumber: busNumber,
      driverName: driverName,
      departureTime: departureTime,
      totalSeats: totalSeats,
      availableSeats: totalSeats,
      status: status,
      agentId: agentId,
      agentCode: agentCode,
      startedOffline: const Value(true),
      isSynced: const Value(false),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final id = await into(trips).insert(companion);
    return (select(trips)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Update trip with server ID after successful sync
  Future<bool> updateTripServerId(String localId, String serverId) async {
    return await (update(trips)..where((t) => t.localId.equals(localId)))
        .write(TripsCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        )) > 0;
  }

  /// Get trips that need to be synced
  Future<List<Trip>> getUnsyncedTrips() async {
    return (select(trips)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Get trip by local ID
  Future<Trip?> getTripByLocalId(String localId) async {
    return (select(trips)..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Queue a trip creation for sync
  Future<void> queueTripCreation(Trip trip) async {
    final tripData = {
      'localId': trip.localId,
      'tripCode': trip.tripCode,
      'routeId': trip.routeId,
      'fleetId': trip.fleetId,
      'busNumber': trip.busNumber,
      'driverName': trip.driverName,
      'departureTime': trip.departureTime.toIso8601String(),
      'totalSeats': trip.totalSeats,
      'availableSeats': trip.availableSeats,
      'status': trip.status,
    };

    await addToSyncQueue(
      SyncQueueCompanion.insert(
        entityType: 'trip',
        entityId: trip.id,
        operation: 'create',
        data: jsonEncode(tripData),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Get trip by server ID
  Future<Trip?> getTripByServerId(String serverId) async {
    return (select(trips)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  /// End a trip locally (offline operation)
  Future<Trip> endTripLocally(String tripId, bool isLocalId) async {
    final query = isLocalId 
        ? (update(trips)..where((t) => t.localId.equals(tripId)))
        : (update(trips)..where((t) => t.serverId.equals(tripId)));
    
    await query.write(TripsCompanion(
      status: const Value('completed'),
      arrivalTime: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
    
    // Retrieve and return the updated trip
    final trip = isLocalId
        ? await getTripByLocalId(tripId)
        : await getTripByServerId(tripId);
    
    if (trip == null) {
      throw Exception('Trip not found after update');
    }
    
    return trip;
  }

  /// Queue a trip end for sync
  Future<void> queueTripEnd(Trip trip) async {
    final tripData = {
      'localId': trip.localId,
      'serverId': trip.serverId,
      'tripCode': trip.tripCode,
      'status': trip.status,
      'arrivalTime': trip.arrivalTime?.toIso8601String(),
    };

    await addToSyncQueue(
      SyncQueueCompanion.insert(
        entityType: 'trip',
        entityId: trip.id,
        operation: 'end',
        data: jsonEncode(tripData),
        createdAt: DateTime.now(),
      ),
    );
  }

  // Ticket operations
  
  /// Get all unsynced tickets for manual sync operation
  Future<List<Ticket>> getUnsyncedTickets() async {
    return (select(tickets)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Get ticket by local ID (UUID)
  Future<Ticket?> getTicketByLocalId(String localId) async {
    return (select(tickets)..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Get ticket by server ID (UUID from backend)
  Future<Ticket?> getTicketByServerId(String serverId) async {
    return (select(tickets)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  /// Get all tickets for a trip (supports both local and server trip IDs)
  Future<List<Ticket>> getTicketsByTripId(String tripId, bool isLocalId) async {
    if (isLocalId) {
      return (select(tickets)
            ..where((t) => t.tripLocalId.equals(tripId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.issuedAt, mode: OrderingMode.desc)
            ]))
          .get();
    } else {
      return (select(tickets)
            ..where((t) => t.tripServerId.equals(tripId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.issuedAt, mode: OrderingMode.desc)
            ]))
          .get();
    }
  }

  /// Get tickets by trip using both local and server IDs
  /// This is more flexible and handles synced trips correctly
  Future<List<Ticket>> getTicketsByTripIds({
    required String localId,
    String? serverId,
    required String agentId,
  }) async {
    if (serverId != null) {
      // Query for tickets matching either the local ID or server ID, filtered by agent
      return (select(tickets)
            ..where((t) => 
              (t.tripLocalId.equals(localId) | t.tripServerId.equals(serverId)) & 
              t.agentId.equals(agentId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.issuedAt, mode: OrderingMode.desc)
            ]))
          .get();
    } else {
      // Only local ID available, filtered by agent
      return (select(tickets)
            ..where((t) => t.tripLocalId.equals(localId) & t.agentId.equals(agentId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.issuedAt, mode: OrderingMode.desc)
            ]))
          .get();
    }
  }

  /// Create a ticket locally for offline operation
  /// CRITICAL: Includes agentId for agent isolation on shared devices
  Future<Ticket> createTicketLocally({
    required String localId,
    required String tripLocalId,
    String? tripServerId,
    required String ticketCategory,
    required String currency,
    required double amount,
    String? departure,
    String? destination,
    String? linkedPassengerTicketId,
    required String agentId,
    required String agentCode,
  }) async {
    final ticketId = await into(tickets).insert(
      TicketsCompanion.insert(
        localId: localId,
        tripLocalId: Value(tripLocalId),
        tripServerId: Value(tripServerId),
        ticketCategory: ticketCategory,
        currency: currency,
        amount: amount,
        departure: Value(departure),
        destination: Value(destination),
        linkedPassengerTicketId: Value(linkedPassengerTicketId),
        agentId: agentId,
        agentCode: agentCode,
        issuedAt: DateTime.now(),
        issuedOffline: const Value(true),
        isSynced: const Value(false),
      ),
    );

    final ticket = await (select(tickets)..where((t) => t.id.equals(ticketId)))
        .getSingleOrNull();
    return ticket!;
  }

  /// Queue a ticket for sync to backend
  Future<void> queueTicketIssue(Ticket ticket) async {
    final data = {
      'localId': ticket.localId,
      'tripLocalId': ticket.tripLocalId,
      'tripServerId': ticket.tripServerId,
      'ticketCategory': ticket.ticketCategory,
      'currency': ticket.currency,
      'amount': ticket.amount,
      'departure': ticket.departure,
      'destination': ticket.destination,
      'linkedPassengerTicketId': ticket.linkedPassengerTicketId,
      'issuedAt': ticket.issuedAt.toIso8601String(),
    };

    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'ticket',
        entityId: ticket.id,
        operation: 'create',
        data: json.encode(data),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Mark ticket as synced by local ID and update with server ID
  Future<bool> markTicketAsSyncedByLocalId(
    String localId,
    String serverId,
    String? serialNumber,
  ) async {
    return await (update(tickets)..where((t) => t.localId.equals(localId)))
            .write(
          TicketsCompanion(
            serverId: Value(serverId),
            serialNumber: Value(serialNumber),
            isSynced: const Value(true),
            syncError: const Value(null),
          ),
        ) >
        0;
  }

  /// Mark ticket as synced by internal ID (for old compatibility)
  Future<bool> markTicketAsSynced(int ticketId) async {
    return await (update(tickets)..where((t) => t.id.equals(ticketId)))
            .write(const TicketsCompanion(isSynced: Value(true))) >
        0;
  }

  /// Update ticket sync error
  Future<bool> updateTicketSyncError(
      String localId, String error, DateTime attemptTime) async {
    return await (update(tickets)..where((t) => t.localId.equals(localId)))
            .write(
          TicketsCompanion(
            syncError: Value(error),
            lastSyncAttemptAt: Value(attemptTime),
          ),
        ) >
        0;
  }

  // Sync queue operations
  Future<List<SyncQueueData>> getPendingSyncItems() async {
    return (select(syncQueue)
          ..orderBy([
            (q) => OrderingTerm(expression: q.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> addToSyncQueue(SyncQueueCompanion item) async {
    return into(syncQueue).insert(item);
  }

  Future<bool> removeSyncQueueItem(int id) async {
    return await (delete(syncQueue)..where((q) => q.id.equals(id))).go() > 0;
  }

  Future<bool> incrementSyncRetry(int id, String error) async {
    final item = await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return false;

    return await (update(syncQueue)..where((q) => q.id.equals(id))).write(
          SyncQueueCompanion(
            retryCount: Value(item.retryCount + 1),
            lastAttemptAt: Value(DateTime.now()),
            error: Value(error),
          ),
        ) >
        0;
  }

  // Clear all data (logout)
  Future<void> clearAllData() async {
    await (delete(tickets)).go();
    await (delete(trips)).go();
    await (delete(routes)).go();
    await (delete(agents)).go();
    await (delete(syncQueue)).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'countryboy_conductor.db'));
    return NativeDatabase.createInBackground(file);
  });
}
