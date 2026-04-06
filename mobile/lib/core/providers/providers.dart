import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../storage/storage_service.dart';
import '../../data/api/auth_api_service.dart';
import '../../data/api/trip_api_service.dart';
import '../../data/api/ticket_api_service.dart';
import '../../data/local/database.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/dto/trip_dto.dart';
import '../../services/sync_service.dart';

// ========== Core Services ==========

/// Flutter secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

/// Dio client provider
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient.getInstance(secureStorage);
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized first');
});

/// Local database provider
/// Must be initialized in main() before app starts
final localDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('AppDatabase must be initialized in main()');
});

// ========== API Services ==========

/// Auth API service provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthApiService(dioClient);
});

// ========== Repositories ==========

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(apiService, storageService);
});

// ========== Auth State Providers ==========

/// Device pairing status provider
final isPairedProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.isPaired();
});

/// Agent login status provider
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.isLoggedIn();
});

/// Current agent provider
final currentAgentProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentAgent();
});

/// Merchant code provider
final merchantCodeProvider = Provider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getMerchantCode();
});

// ========== Trip Management ==========

/// Trip API service provider
final tripApiServiceProvider = Provider<TripApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TripApiService(storage: storageService);
});

/// Trip repository provider
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiService = ref.watch(tripApiServiceProvider);
  final database = ref.watch(localDatabaseProvider);
  final storageService = ref.watch(storageServiceProvider);
  return TripRepository(
    apiService: apiService,
    database: database,
    storageService: storageService,
  );
});

// ========== Ticket Management ==========

/// Ticket API service provider
final ticketApiServiceProvider = Provider<TicketApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TicketApiService(storage: storageService);
});

/// Ticket repository provider
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final apiService = ref.watch(ticketApiServiceProvider);
  final database = ref.watch(localDatabaseProvider);
  final storageService = ref.watch(storageServiceProvider);
  return TicketRepository(
    apiService: apiService,
    database: database,
    storageService: storageService,
  );
});

// ========== Trip State Providers ==========

/// Active trip provider
/// 
/// Watches agent's current active trip
/// Returns null if no active trip
/// Auto-refreshes when trip state changes
final activeTripProvider = StreamProvider<TripDto?>((ref) async* {
  final tripRepo = ref.watch(tripRepositoryProvider);
  
  // Initial load
  yield await tripRepo.getActiveTrip();
  
  // Poll every 30 seconds for updates
  // (Future enhancement: Use WebSocket for real-time updates)
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await tripRepo.getActiveTrip();
  }
});

/// Can start trip provider
/// 
/// Business rule: One active trip per agent at a time
/// Returns true if agent has no active trip
final canStartTripProvider = FutureProvider<bool>((ref) async {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return await tripRepo.canStartTrip();
});

/// Available fleets provider
/// 
/// Lists all fleet vehicles in agent's depot
/// Used for fleet selection dropdown
final availableFleetsProvider = FutureProvider<List<FleetDto>>((ref) async {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return await tripRepo.getFleets();
});

/// Available routes provider
/// 
/// Lists all routes in agent's depot
/// Used for route selection dropdown
final availableRoutesProvider = FutureProvider<List<RouteDto>>((ref) async {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return await tripRepo.getRoutes();
});

/// Fleets cache age provider
/// 
/// Returns timestamp of last fleet data cache
/// Used to show cache freshness indicator
final fleetsCacheAgeProvider = FutureProvider<DateTime?>((ref) async {
  final database = ref.watch(localDatabaseProvider);
  return await database.getLastCacheTime('fleets');
});

/// Routes cache age provider
/// 
/// Returns timestamp of last route data cache
/// Used to show cache freshness indicator
final routesCacheAgeProvider = FutureProvider<DateTime?>((ref) async {
  final database = ref.watch(localDatabaseProvider);
  return await database.getLastCacheTime('routes');
});

/// Trip stats provider
/// 
/// Calculates current trip statistics
/// Returns tickets count and total revenue
final tripStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final activeTripAsync = ref.watch(activeTripProvider);
  
  return activeTripAsync.when(
    data: (trip) {
      if (trip == null) {
        return {'tickets_count': 0, 'total_revenue': 0.0};
      }
      return {
        'tickets_count': trip.ticketsCount ?? 0,
        'total_revenue': trip.totalRevenue ?? 0.0,
      };
    },
    loading: () => {'tickets_count': 0, 'total_revenue': 0.0},
    error: (_, __) => {'tickets_count': 0, 'total_revenue': 0.0},
  );
});

// ========== Sync Management ==========

/// Sync service provider
/// 
/// Manages background synchronization of offline operations
/// Auto-starts when initialized
final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(localDatabaseProvider);
  final apiService = ref.watch(tripApiServiceProvider);
  final ticketApiService = ref.watch(ticketApiServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final storageService = ref.watch(storageServiceProvider);
  
  final service = SyncService(
    database: database,
    apiService: apiService,
    ticketApiService: ticketApiService,
    authRepository: authRepository,
    storageService: storageService,
  );
  
  // Start monitoring connectivity
  service.start();
  
  // Cleanup on dispose
  ref.onDispose(() {
    service.stop();
  });
  
  return service;
});

/// Pending sync count provider
/// 
/// Returns count of operations waiting to be synced
/// Used to show sync status badge
final pendingSyncCountProvider = StreamProvider<int>((ref) async* {
  final syncService = ref.watch(syncServiceProvider);
  
  // Initial count
  yield await syncService.getPendingSyncCount();
  
  // Poll every 10 seconds for updates
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    yield await syncService.getPendingSyncCount();
  }
});

