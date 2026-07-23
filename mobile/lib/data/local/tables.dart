import 'package:drift/drift.dart';

class CachedFleets extends Table {
  TextColumn get id => text()();
  TextColumn get number => text()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  IntColumn get capacity => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRoutes extends Table {
  TextColumn get id => text()();
  TextColumn get origin => text()();
  TextColumn get destination => text()();
  /// JSON array of parent corridor route ids.
  TextColumn get parentRouteIdsJson => text().withDefault(const Constant('[]'))();
  /// JSON array of direct child segment route ids.
  TextColumn get childRouteIdsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedFares extends Table {
  TextColumn get id => text()();
  TextColumn get routeId => text()();
  TextColumn get currency => text()();
  RealColumn get amount => real()();
  TextColumn get routeLabel => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalTrips extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text()();
  TextColumn get fleetId => text()();
  TextColumn get routeId => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get depotId => text()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  BoolColumn get startedOffline =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get fleetNumber => text().nullable()();
  TextColumn get routeOrigin => text().nullable()();
  TextColumn get routeDestination => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalTickets extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get agentId => text()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get depotId => text()();
  TextColumn get ticketCategory => text()();
  TextColumn get currency => text()();
  RealColumn get amount => real()();
  TextColumn get departure => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get passengerName => text().nullable()();
  TextColumn get passengerPhone => text().nullable()();
  RealColumn get luggageAmount => real().nullable()();
  TextColumn get luggageDescription => text().nullable()();
  IntColumn get serialNumber => integer().nullable()();
  DateTimeColumn get issuedAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get idempotencyKey => text()();
  TextColumn get lastError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {idempotencyKey},
      ];
}

class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
