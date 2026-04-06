import 'package:drift/drift.dart';

/// Devices table for storing pairing information
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceToken => text().unique()();
  TextColumn get merchantCode => text()();
  TextColumn get deviceName => text()();
  TextColumn get deviceModel => text()();
  DateTimeColumn get pairedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Agents table for caching agent information
class Agents extends Table {
  IntColumn get id => integer()();
  TextColumn get agentCode => text().unique()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get role => text()();
  TextColumn get merchantCode => text()();
  TextColumn get merchantName => text()();
  TextColumn get depotCode => text()();
  TextColumn get depotName => text()();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Routes table for bus routes
class Routes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique()(); // API ID like "route-hre-001"
  TextColumn get routeCode => text()();
  TextColumn get routeName => text()();
  TextColumn get origin => text()();
  TextColumn get destination => text()();
  RealColumn get fare => real()(); // Base fare
  IntColumn get distanceKm => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Trips table for scheduled trips
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique().nullable()(); // Backend UUID after sync
  TextColumn get localId => text().unique()(); // Locally generated UUID
  TextColumn get tripCode => text().unique()();
  TextColumn get routeId => text()(); // References Routes.serverId
  TextColumn get fleetId => text()(); // References Fleets.serverId
  TextColumn get busNumber => text()(); // Redundant but kept for display
  TextColumn get driverName => text()();
  DateTimeColumn get departureTime => dateTime()();
  DateTimeColumn get arrivalTime => dateTime().nullable()();
  TextColumn get status =>
      text()(); // scheduled, boarding, in_transit, completed, cancelled
  IntColumn get totalSeats => integer()();
  IntColumn get availableSeats => integer()();
  
  // Agent isolation - CRITICAL for multi-agent devices
  TextColumn get agentId => text()(); // Agent server ID who created this trip
  TextColumn get agentCode => text()(); // Agent code for display/debugging
  
  BoolColumn get startedOffline => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Tickets table for issued tickets
/// Matches backend tblTickets structure for offline-first ticket issuing
class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Identity - support offline (localId) and online (serverId)
  TextColumn get localId => text().unique()(); // UUID generated offline
  TextColumn get serverId => text().unique().nullable()(); // UUID from backend after sync
  
  // Trip references - flexible to support offline/online trips
  TextColumn get tripLocalId => text().nullable()(); // Links to Trips.localId
  TextColumn get tripServerId => text().nullable()(); // Links to backend trip_id
  
  // Ticket details matching backend schema
  TextColumn get serialNumber => text().nullable()(); // Backend assigns serial number
  TextColumn get ticketCategory => text()(); // PASSENGER, LUGGAGE
  TextColumn get currency => text()(); // ZWL, USD
  RealColumn get amount => real()(); // Ticket price
  
  // Route information (optional, inherited from trip route)
  TextColumn get departure => text().nullable()();
  TextColumn get destination => text().nullable()();
  
  // Luggage ticket linking (for LUGGAGE category)
  TextColumn get linkedPassengerTicketId => text().nullable()(); // Links to passenger ticket localId/serverId
  
  // Agent isolation - CRITICAL for multi-agent devices
  TextColumn get agentId => text()(); // Agent server ID who issued this ticket
  TextColumn get agentCode => text()(); // Agent code for display/debugging
  
  // Timestamps
  DateTimeColumn get issuedAt => dateTime()();
  
  // Offline tracking
  BoolColumn get issuedOffline => boolean().withDefault(const Constant(false))();
  
  // Sync status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get lastSyncAttemptAt => dateTime().nullable()();
}

/// SyncQueue table for tracking sync operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType =>
      text()(); // ticket, trip, etc.
  IntColumn get entityId => integer()();
  TextColumn get operation =>
      text()(); // create, update, delete
  TextColumn get data => text()(); // JSON payload
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();
}

/// Fleets table for bus vehicles (cached from API)
class Fleets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique()(); // API ID like "fleet-hre-001"
  TextColumn get number => text()();
  TextColumn get depotId => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Cache metadata table for tracking data freshness
class CacheMetadata extends Table {
  TextColumn get dataType => text()(); // 'fleets', 'routes'
  DateTimeColumn get lastCachedAt => dateTime()();
  IntColumn get recordCount => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {dataType};
}
