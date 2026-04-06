import '../api/trip_api_service.dart';
import '../dto/trip_dto.dart';
import '../local/database.dart';
import '../../core/storage/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

/// Trip Repository
/// 
/// Business logic layer for trip operations
/// Handles error handling, validation, and state management
class TripRepository {
  final TripApiService _apiService;
  final AppDatabase _database;
  final StorageService _storageService;
  final Connectivity _connectivity;
  final Uuid _uuid;

  TripRepository({
    required TripApiService apiService,
    required AppDatabase database,
    required StorageService storageService,
    Connectivity? connectivity,
    Uuid? uuid,
  })  : _apiService = apiService,
        _database = database,
        _storageService = storageService,
        _connectivity = connectivity ?? Connectivity(),
        _uuid = uuid ?? const Uuid();

  /// Start a new trip
  /// 
  /// Validates:
  /// - Fleet ID is provided and valid
  /// - Route ID is provided and valid
  /// - Agent doesn't already have an active trip
  /// 
  /// Strategy:
  /// 1. Check connectivity
  /// 2. If online, try API first
  /// 3. If offline or API fails, create locally and queue for sync
  /// 
  /// Returns: Started trip details
  /// Throws: Exception with user-friendly error message
  Future<TripDto> startTrip({
    required String fleetId,
    required String routeId,
    String? deviceId,
  }) async {
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    debugPrint('📡 Device is ${isOnline ? "online" : "offline"}');
    
    if (isOnline) {
      // Try API first when online
      try {
        debugPrint('🌐 Attempting online trip creation...');
        final request = StartTripRequest(
          fleetId: fleetId,
          routeId: routeId,
          deviceId: deviceId,
          startedOffline: false,
        );

        final response = await _apiService.startTrip(request);
        debugPrint('✅ Trip created online: ${response.trip.id}');
        return response.trip;
      } catch (e) {
        debugPrint('⚠️ Online creation failed: $e');
        debugPrint('🔄 Falling back to offline mode...');
        // Fall through to offline creation
      }
    }
    
    // Create offline (either because offline or API failed)
    return _createTripOffline(
      fleetId: fleetId,
      routeId: routeId,
      deviceId: deviceId,
    );
  }
  
  /// Create a trip locally for offline operation
  Future<TripDto> _createTripOffline({
    required String fleetId,
    required String routeId,
    String? deviceId,
  }) async {
    try {
      debugPrint('💾 Creating trip offline...');
      
      // Get current agent info (CRITICAL for agent isolation)
      final agentData = await _storageService.getAgentData();
      if (agentData == null) {
        throw Exception('Not authenticated - please log in again');
      }
      
      final agentId = agentData['id']?.toString() ?? '';
      final agentCode = agentData['agent_code']?.toString() ?? '';
      
      if (agentId.isEmpty || agentCode.isEmpty) {
        throw Exception('Agent information missing - please log in again');
      }
      
      final localId = _uuid.v4();
      final tripCode = 'TRIP-${DateTime.now().millisecondsSinceEpoch}';
      
      // Get fleet number for display
      final fleets = await _database.getCachedFleets();
      final fleet = fleets.firstWhere((f) => f.id == fleetId, 
        orElse: () => FleetDto(id: fleetId, number: 'Unknown', depotId: ''));
      
      // Create in local database with minimal required fields
      final trip = await _database.createTripLocally(
        localId: localId,
        tripCode: tripCode,
        routeId: routeId,
        fleetId: fleetId,
        busNumber: fleet.number,
        driverName: 'TBD', // Will be updated when synced
        departureTime: DateTime.now(),
        totalSeats: 50, // Default, will be updated when synced
        status: 'scheduled', // Use 'scheduled' status for offline trips
        agentId: agentId,
        agentCode: agentCode,
      );
      
      // Queue for sync
      await _database.queueTripCreation(trip);
      
      debugPrint('✅ Trip created offline: $localId');
      debugPrint('📤 Queued for sync');
      
      // Get route for display
      final routes = await _database.getCachedRoutes();
      final route = routes.firstWhere((r) => r.id == routeId,
        orElse: () => RouteDto(id: routeId, origin: 'Unknown', destination: 'Unknown', depotId: ''));
      
      // Convert to DTO matching backend structure
      return TripDto(
        id: localId, // Use local ID until synced
        depotId: fleet.depotId,
        agentId: '', // Backend will fill this
        fleetId: fleetId,
        routeId: routeId,
        deviceId: deviceId,
        startedAt: trip.departureTime,
        status: 'scheduled', // Offline trips start as 'scheduled'
        startedOffline: true,
        fleet: TripFleetDto(id: fleetId, number: fleet.number),
        route: TripRouteDto(id: routeId, origin: route.origin, destination: route.destination),
      );
    } catch (e) {
      debugPrint('❌ Offline creation failed: $e');
      throw Exception('Failed to create trip offline: ${e.toString()}');
    }
  }

  /// End an active trip
  /// 
  /// Strategy:
  /// 1. Check connectivity
  /// 2. If online, try API first
  /// 3. If offline or API fails, end locally and queue for sync
  /// 
  /// Validates:
  /// - Trip exists locally
  /// - Trip is still active (not already completed)
  /// 
  /// Returns: Completed trip with status='completed'
  /// Throws: Exception with user-friendly error message
  Future<TripDto> endTrip(String tripId) async {
    // Check if this is a local ID (UUID format)
    final isLocalId = _isUuidFormat(tripId);
    
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    debugPrint('📡 Device is ${isOnline ? "online" : "offline"}');
    
    if (isOnline) {
      // Try API first when online
      try {
        debugPrint('🌐 Attempting online trip ending...');
        
        // Get the server ID if this is a local trip
        String apiTripId = tripId;
        if (isLocalId) {
          final trip = await _database.getTripByLocalId(tripId);
          if (trip?.serverId != null) {
            apiTripId = trip!.serverId!;
            debugPrint('🔄 Using server ID: $apiTripId');
          }
        }
        
        final response = await _apiService.endTrip(apiTripId);
        debugPrint('✅ Trip ended online: ${response.trip.id}');
        
        // Update local database only if trip exists locally
        if (isLocalId) {
          final localTrip = await _database.getTripByLocalId(tripId);
          if (localTrip != null) {
            await _database.endTripLocally(tripId, true);
            debugPrint('✅ Local database updated');
          }
        } else {
          final localTrip = await _database.getTripByServerId(tripId);
          if (localTrip != null) {
            await _database.endTripLocally(tripId, false);
            debugPrint('✅ Local database updated');
          }
        }
        
        return response.trip;
      } catch (e) {
        debugPrint('⚠️ Online ending failed: $e');
        debugPrint('🔄 Falling back to offline mode...');
        // Fall through to offline ending
      }
    }
    
    // End offline (either because offline or API failed)
    return _endTripOffline(tripId, isLocalId);
  }
  
  /// End a trip locally for offline operation
  Future<TripDto> _endTripOffline(String tripId, bool isLocalId) async {
    try {
      debugPrint('💾 Ending trip offline...');
      
      // Try to get the trip from local database
      // First try as local ID, then as server ID
      Trip? trip;
      bool foundAsLocalId = false;
      
      if (isLocalId) {
        trip = await _database.getTripByLocalId(tripId);
        foundAsLocalId = true;
      }
      
      // If not found and format looks like UUID, try server ID
      if (trip == null) {
        trip = await _database.getTripByServerId(tripId);
        foundAsLocalId = false;
      }
      
      // If still not found, try the opposite
      if (trip == null && !isLocalId) {
        trip = await _database.getTripByLocalId(tripId);
        foundAsLocalId = true;
      }
      
      if (trip == null) {
        throw Exception('Trip not found in local database');
      }
      
      if (trip.status == 'completed') {
        throw Exception('Trip is already completed');
      }
      
      // Update trip status locally using the correct ID and type
      final actualId = foundAsLocalId ? trip.localId : (trip.serverId ?? trip.localId);
      final updatedTrip = await _database.endTripLocally(actualId, foundAsLocalId);
      
      // Queue for sync
      await _database.queueTripEnd(updatedTrip);
      
      debugPrint('✅ Trip ended offline: $actualId');
      debugPrint('📤 Queued for sync');
      
      // Get fleet and route for display
      final fleets = await _database.getCachedFleets();
      final routes = await _database.getCachedRoutes();
      
      final fleet = fleets.where((f) => f.id == updatedTrip.fleetId).firstOrNull;
      final route = routes.where((r) => r.id == updatedTrip.routeId).firstOrNull;
      
      // Convert to DTO
      return TripDto(
        id: updatedTrip.serverId ?? updatedTrip.localId,
        depotId: '', // Will be filled by backend
        agentId: '', // Will be filled by backend
        fleetId: updatedTrip.fleetId,
        routeId: updatedTrip.routeId,
        startedAt: updatedTrip.departureTime,
        endedAt: updatedTrip.arrivalTime,
        status: updatedTrip.status,
        startedOffline: updatedTrip.startedOffline,
        fleet: fleet != null 
            ? TripFleetDto(id: fleet.id, number: fleet.number)
            : null,
        route: route != null
            ? TripRouteDto(id: route.id, origin: route.origin, destination: route.destination)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Offline ending failed: $e');
      throw Exception('Failed to end trip offline: ${e.toString()}');
    }
  }
  
  /// Check if a string is in UUID format
  bool _isUuidFormat(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  /// Get agent's current active trip
  /// 
  /// Strategy:
  /// 1. Try API first (check server for synced trips)
  /// 2. If API returns null or fails, check local database
  /// 3. Return offline-created trip if found
  /// 
  /// Returns: Active trip or null if no active trip
  /// Used to:
  /// - Check if agent can start new trip
  /// - Display current trip status on home screen
  /// - Validate before issuing tickets
  Future<TripDto?> getActiveTrip() async {
    try {
      // Try API first
      final response = await _apiService.getActiveTrip();
      
      // If API has an active trip, return it
      if (response.trip != null) {
        debugPrint('✅ Found active trip from API: ${response.trip!.id}');
        return response.trip;
      }
      
      // If API returns null (no active trip on server), check local database
      // This handles offline trips that haven't synced yet
      debugPrint('⚠️ No active trip from API, checking local database...');
    } catch (e) {
      debugPrint('⚠️ API getActiveTrip failed: $e');
      debugPrint('📦 Checking local database for offline trips...');
    }
    
    // Fallback to local database (either API returned null or failed)
    try {
      // Get current agent ID for filtering (CRITICAL for agent isolation)
      final agentData = await _storageService.getAgentData();
      if (agentData == null) {
        debugPrint('⚠️ Not authenticated');
        return null;
      }
      
      final agentId = agentData['id']?.toString() ?? '';
      if (agentId.isEmpty) {
        debugPrint('⚠️ Agent ID missing');
        return null;
      }
      
      final activeTrips = await _database.getActiveTrips(agentId);
      
      if (activeTrips.isEmpty) {
        debugPrint('✅ No active trips found locally for agent $agentId');
        return null;
      }
      
      // Get the first active trip
      final trip = activeTrips.first;
      debugPrint('✅ Found active trip: ${trip.localId}');
      
      // Fetch fleet and route data from cache
      final fleets = await _database.getCachedFleets();
      final routes = await _database.getCachedRoutes();
      
      final fleet = fleets.where((f) => f.id == trip.fleetId).firstOrNull;
      final route = routes.where((r) => r.id == trip.routeId).firstOrNull;
      
      // Construct TripDto from local data
      return TripDto(
        id: trip.serverId ?? trip.localId, // Use serverId if synced, otherwise localId
        depotId: '', // Not stored locally yet
        agentId: trip.agentId, // Include agent info from local data
        fleetId: trip.fleetId,
        routeId: trip.routeId,
        startedAt: trip.departureTime,
        status: trip.status,
        startedOffline: trip.startedOffline,
        fleet: fleet != null 
            ? TripFleetDto(id: fleet.id, number: fleet.number)
            : null,
        route: route != null
            ? TripRouteDto(id: route.id, origin: route.origin, destination: route.destination)
            : null,
      );
    } catch (dbError) {
      debugPrint('❌ Local database error: $dbError');
      return null;
    }
  }

  /// Get all available fleets for agent's depot
  /// 
  /// Strategy:
  /// 1. Try to fetch from API (online)
  /// 2. If successful, cache locally and return
  /// 3. If failed (offline), check local cache
  /// 4. Return cached data if available
  /// 5. Throw error if no cache and offline
  /// 
  /// Used for: Fleet selection when starting trip
  /// Returns: List of fleet vehicles (buses)
  Future<List<FleetDto>> getFleets() async {
    try {
      debugPrint('🚌 Fetching fleets from API...');
      final fleets = await _apiService.getFleets();
      
      // Cache successful response
      debugPrint('✅ Got ${fleets.length} fleets, caching...');
      await _database.cacheFleets(fleets);
      
      return fleets;
    } catch (e) {
      debugPrint('⚠️ API failed: $e');
      debugPrint('📦 Checking local cache...');
      
      // Fallback to cache
      final cached = await _database.getCachedFleets();
      
      if (cached.isNotEmpty) {
        final cacheTime = await _database.getLastCacheTime('fleets');
        final age = cacheTime != null 
            ? DateTime.now().difference(cacheTime)
            : null;
        
        debugPrint('✅ Loaded ${cached.length} fleets from cache');
        if (age != null) {
          debugPrint('📅 Cache age: ${_formatDuration(age)}');
        }
        
        return cached;
      }
      
      // No cache available
      debugPrint('❌ No cached fleets available');
      throw Exception(
        'Cannot load fleets. Please connect to internet to download data.'
      );
    }
  }

  /// Get all available routes for agent's depot
  /// 
  /// Strategy: Same cache-first pattern as getFleets()
  /// 
  /// Used for: Route selection when starting trip
  /// Returns: List of routes (origin → destination)
  Future<List<RouteDto>> getRoutes() async {
    try {
      debugPrint('🛣️ Fetching routes from API...');
      final routes = await _apiService.getRoutes();
      
      debugPrint('✅ Got ${routes.length} routes, caching...');
      await _database.cacheRoutes(routes);
      
      return routes;
    } catch (e) {
      debugPrint('⚠️ API failed: $e');
      debugPrint('📦 Checking local cache...');
      
      final cached = await _database.getCachedRoutes();
      
      if (cached.isNotEmpty) {
        final cacheTime = await _database.getLastCacheTime('routes');
        final age = cacheTime != null 
            ? DateTime.now().difference(cacheTime)
            : null;
        
        debugPrint('✅ Loaded ${cached.length} routes from cache');
        if (age != null) {
          debugPrint('📅 Cache age: ${_formatDuration(age)}');
        }
        
        return cached;
      }
      
      debugPrint('❌ No cached routes available');
      throw Exception(
        'Cannot load routes. Please connect to internet to download data.'
      );
    }
  }

  /// Format duration for debug logging
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'just now';
  }

  /// Check if agent can start a new trip
  /// 
  /// Business rule: One active trip per agent at a time
  /// Returns: true if no active trip, false if already has active trip
  Future<bool> canStartTrip() async {
    final activeTrip = await getActiveTrip();
    return activeTrip == null;
  }

  /// Create a new fleet vehicle
  /// 
  /// Allows agents to add new fleet vehicles when not in system
  /// Returns: Newly created fleet
  Future<FleetDto> createFleet(String fleetNumber) async {
    try {
      return await _apiService.createFleet(fleetNumber);
    } catch (e) {
      // Extract user-friendly message
      final message = e.toString().replaceAll('Exception: ', '');
      throw Exception(message);
    }
  }

  /// Create a new route
  /// 
  /// Allows agents to add new routes when not in system
  /// Returns: Newly created route
  Future<RouteDto> createRoute(String origin, String destination) async {
    try {
      return await _apiService.createRoute(origin, destination);
    } catch (e) {
      // Extract user-friendly message
      final message = e.toString().replaceAll('Exception: ', '');
      throw Exception(message);
    }
  }
}
