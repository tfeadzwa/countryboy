import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/models/models.dart';
import '../api/api_services.dart';
import '../local/database.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(
    api: ref.watch(referenceApiProvider),
    db: ref.watch(appDatabaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

class ReferenceRepository {
  ReferenceRepository({
    required ReferenceApi api,
    required AppDatabase db,
    required ConnectivityService connectivity,
    required SecureStorageService storage,
  })  : _api = api,
        _db = db,
        _connectivity = connectivity,
        _storage = storage;

  final ReferenceApi _api;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final SecureStorageService _storage;

  Future<bool> _canFetchFromApi() async {
    if (!await _connectivity.checkReachability()) return false;
    return _storage.hasOnlineAuth();
  }

  Future<void> cacheFromPullSnapshot(Map<String, dynamic> data) async {
    final fleets = data['fleets'] as List<dynamic>?;
    if (fleets != null && fleets.isNotEmpty) {
      await _cacheFleets(
        fleets
            .map((e) => FleetModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes != null && routes.isNotEmpty) {
      await _cacheRoutes(
        _mergeRouteGraph(
          routes
              .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
    }

    final fares = data['fares'] as List<dynamic>?;
    if (fares != null && fares.isNotEmpty) {
      await _cacheFares(
        fares
            .map((e) => FareModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final drivers = data['drivers'] as List<dynamic>?;
    if (drivers != null && drivers.isNotEmpty) {
      await _cacheDrivers(
        drivers
            .map((e) => DriverModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
  }

  Future<void> _cacheFleets(List<FleetModel> fleets) async {
    await _db.cacheFleets(
      fleets
          .map(
            (f) => CachedFleetsCompanion.insert(
              id: f.id,
              number: f.number,
              registrationNumber: Value(f.registrationNumber),
              status: Value(f.status ?? 'ACTIVE'),
              cachedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  Future<void> _cacheDrivers(List<DriverModel> drivers) async {
    await _db.cacheDrivers(
      drivers
          .map(
            (d) => CachedDriversCompanion.insert(
              id: d.id,
              fullName: d.fullName,
              status: Value(d.status ?? 'ACTIVE'),
              cachedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  Future<void> _cacheRoutes(List<RouteModel> routes) async {
    final merged = _mergeRouteGraph(routes);
    await _db.cacheRoutes(
      merged
          .map(
            (r) => CachedRoutesCompanion.insert(
              id: r.id,
              origin: r.origin,
              destination: r.destination,
              parentRouteIdsJson: Value(jsonEncode(r.parentRouteIds)),
              childRouteIdsJson: Value(jsonEncode(r.childRouteIds)),
              isActive: Value(r.isActive),
              cachedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  /// Ensures linked child routes from API snapshots are present in the cache.
  List<RouteModel> _mergeRouteGraph(List<RouteModel> routes) {
    final byId = {for (final r in routes) r.id: r};
    for (final route in routes) {
      for (final child in route.embeddedChildren) {
        byId.putIfAbsent(child.id, () => child);
      }
    }
    return byId.values.toList();
  }

  Future<void> refreshReferenceDataIfOnline() async {
    if (!await _canFetchFromApi()) return;
    try {
      final routes = _mergeRouteGraph(await _api.getRoutes());
      await _cacheRoutes(routes);
      await _cacheFares(await _api.getFares());
    } catch (_) {
      // Caller falls back to cached data.
    }
  }

  Future<void> _cacheFares(List<FareModel> fares) async {
    await _db.cacheFares(
      fares
          .map(
            (f) => CachedFaresCompanion.insert(
              id: f.id,
              routeId: f.routeId,
              currency: f.currency,
              amount: f.amount,
              routeLabel: Value(f.routeLabel),
              cachedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  Future<List<FleetModel>> getFleets() async {
    try {
      if (await _canFetchFromApi()) {
        final fleets = await _api.getFleets();
        await _cacheFleets(fleets);
        return fleets;
      }
    } catch (_) {
      // Fall through to cache.
    }
    final cached = await _db.getCachedFleets();
    if (cached.isEmpty) {
      throw ApiError(
        message: await _storage.hasOnlineAuth()
            ? 'No fleet data available. Connect to download fleet list.'
            : 'No fleet data available. Sign in while online to download buses and routes.',
      );
    }
    return cached
        .map(
          (f) => FleetModel(
            id: f.id,
            number: f.number,
            registrationNumber: f.registrationNumber,
            status: f.status,
          ),
        )
        .toList();
  }

  Future<List<DriverModel>> getDrivers() async {
    try {
      if (await _canFetchFromApi()) {
        final drivers = await _api.getDrivers();
        await _cacheDrivers(drivers);
        // Empty depot is valid — callers show a friendly empty state.
        return drivers;
      }
    } catch (_) {
      // Fall through to cache.
    }
    final cached = await _db.getCachedDrivers();
    return cached
        .where((d) => d.status == 'ACTIVE')
        .map(
          (d) => DriverModel(
            id: d.id,
            fullName: d.fullName,
            status: d.status,
          ),
        )
        .toList();
  }

  List<String> _decodeIdList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      if (await _canFetchFromApi()) {
        final routes = _mergeRouteGraph(await _api.getRoutes());
        await _cacheRoutes(routes);
        return routes;
      }
    } catch (_) {}

    final cached = await _db.getCachedRoutes();
    if (cached.isEmpty) {
      throw ApiError(
        message: await _storage.hasOnlineAuth()
            ? 'No route data available. Connect to download routes.'
            : 'No route data available. Sign in while online to download buses and routes.',
      );
    }
    return cached
        .map(
          (r) => RouteModel(
            id: r.id,
            origin: r.origin,
            destination: r.destination,
            parentRouteIds: _decodeIdList(r.parentRouteIdsJson),
            childRouteIds: _decodeIdList(r.childRouteIdsJson),
            isActive: r.isActive,
          ),
        )
        .toList();
  }

  Future<List<FareModel>> getFares() async {
    try {
      if (await _canFetchFromApi()) {
        final fares = await _api.getFares();
        await _cacheFares(fares);
        return fares;
      }
    } catch (_) {}

    final cached = await _db.getCachedFares();
    if (cached.isEmpty) {
      throw ApiError(message: 'No fare data available offline.');
    }
    return cached
        .map(
          (f) => FareModel(
            id: f.id,
            routeId: f.routeId,
            currency: f.currency,
            amount: f.amount,
            routeLabel: f.routeLabel,
          ),
        )
        .toList();
  }

  Future<FareModel?> getFareForRoute(String routeId, {String currency = 'USD'}) async {
    final fares = await getFaresForRoute(routeId);
    return fares.cast<FareModel?>().firstWhere(
          (f) => f!.currency == currency,
          orElse: () => null,
        );
  }

  Future<List<FareModel>> getFaresForRoute(String routeId) async {
    final fares = await getFares();
    return fares.where((f) => f.routeId == routeId).toList();
  }

  /// All active depot routes for trip start (not limited to parent corridors).
  Future<List<RouteModel>> getMainRoutes() async {
    final routes = await getRoutes();
    final active = routes.where((r) => r.isActive).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return active;
  }

  /// Ticket issue options: main corridor first, then linked segment (child) routes.
  /// The trip's main route is always included even when children exist.
  Future<List<RouteModel>> getTicketRouteOptions(String tripRouteId) async {
    final routes = await getRoutes();
    final byId = {for (final r in routes) r.id: r};
    final tripRoute = byId[tripRouteId];
    if (tripRoute == null || !tripRoute.isActive) return const [];

    final corridor = tripRoute.hasChildren
        ? tripRoute
        : tripRoute.hasParents
            ? (byId[tripRoute.parentRouteIds.first] ?? tripRoute)
            : tripRoute;

    final children = _resolveLinkedChildren(corridor, routes, byId);
    final options = <String, RouteModel>{};
    if (corridor.isActive) {
      options[corridor.id] = corridor;
    }
    for (final child in children) {
      options[child.id] = child;
    }
    // Always keep the trip's selected route in the list (main included with children).
    options.putIfAbsent(tripRouteId, () => tripRoute);

    final headId = corridor.isActive ? corridor.id : tripRouteId;
    final head = options.remove(headId)!;
    final tail = options.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return [
      head,
      ...tail.where((route) => route.id != head.id),
    ];
  }

  List<RouteModel> _resolveLinkedChildren(
    RouteModel corridor,
    List<RouteModel> routes,
    Map<String, RouteModel> byId,
  ) {
    final resolved = <RouteModel>[];
    if (corridor.childRouteIds.isNotEmpty) {
      for (final id in corridor.childRouteIds) {
        final route = byId[id];
        if (route != null && route.isActive) {
          resolved.add(route);
        }
      }
    }

    if (resolved.isEmpty) {
      resolved.addAll(
        routes.where(
          (route) =>
              route.isActive && route.parentRouteIds.contains(corridor.id),
        ),
      );
    }

    if (resolved.isEmpty && corridor.embeddedChildren.isNotEmpty) {
      resolved.addAll(
        corridor.embeddedChildren.where((route) => route.isActive),
      );
    }

    resolved.sort((a, b) => a.label.compareTo(b.label));
    return resolved;
  }
}
