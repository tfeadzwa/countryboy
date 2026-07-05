import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../domain/models/models.dart';
import '../api/api_services.dart';
import '../local/database.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(
    api: ref.watch(referenceApiProvider),
    db: ref.watch(appDatabaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class ReferenceRepository {
  ReferenceRepository({
    required ReferenceApi api,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _api = api,
        _db = db,
        _connectivity = connectivity;

  final ReferenceApi _api;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<List<FleetModel>> getFleets() async {
    try {
      if (await _connectivity.checkReachability()) {
        final fleets = await _api.getFleets();
        await _db.cacheFleets(
          fleets
              .map(
                (f) => CachedFleetsCompanion.insert(
                  id: f.id,
                  number: f.number,
                  status: Value(f.status ?? 'ACTIVE'),
                  cachedAt: DateTime.now(),
                ),
              )
              .toList(),
        );
        return fleets;
      }
    } catch (_) {
      // Fall through to cache.
    }
    final cached = await _db.getCachedFleets();
    if (cached.isEmpty) {
      throw ApiError(
        message: 'No fleet data available. Connect to download fleet list.',
      );
    }
    return cached
        .map((f) => FleetModel(id: f.id, number: f.number, status: f.status))
        .toList();
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      if (await _connectivity.checkReachability()) {
        final routes = await _api.getRoutes();
        await _db.cacheRoutes(
          routes
              .map(
                (r) => CachedRoutesCompanion.insert(
                  id: r.id,
                  origin: r.origin,
                  destination: r.destination,
                  isActive: Value(r.isActive),
                  cachedAt: DateTime.now(),
                ),
              )
              .toList(),
        );
        return routes;
      }
    } catch (_) {}

    final cached = await _db.getCachedRoutes();
    if (cached.isEmpty) {
      throw ApiError(
        message: 'No route data available. Connect to download routes.',
      );
    }
    return cached
        .map(
          (r) => RouteModel(
            id: r.id,
            origin: r.origin,
            destination: r.destination,
            isActive: r.isActive,
          ),
        )
        .toList();
  }

  Future<List<FareModel>> getFares() async {
    try {
      if (await _connectivity.checkReachability()) {
        final fares = await _api.getFares();
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
    final cached = await _db.getFareForRoute(routeId, currency: currency);
    if (cached != null) {
      return FareModel(
        id: cached.id,
        routeId: cached.routeId,
        currency: cached.currency,
        amount: cached.amount,
        routeLabel: cached.routeLabel,
      );
    }
    final fares = await getFares();
    return fares.cast<FareModel?>().firstWhere(
          (f) => f!.routeId == routeId && f.currency == currency,
          orElse: () => null,
        );
  }
}
