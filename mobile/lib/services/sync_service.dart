import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/api/trip_api_service.dart';
import '../data/api/ticket_api_service.dart';
import '../data/dto/trip_dto.dart' show StartTripRequest, TripDto;
import '../data/dto/ticket_dto.dart' show IssueTicketRequest, TicketCategory;
import '../domain/repositories/auth_repository.dart';
import '../core/storage/storage_service.dart';

/// Service for syncing offline operations with the backend
class SyncService {
  final AppDatabase _database;
  final TripApiService _apiService;
  final TicketApiService _ticketApiService;
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final Connectivity _connectivity;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  static const int _maxRetries = 3;
  static const Duration _syncInterval = Duration(minutes: 5);
  
  SyncService({
    required AppDatabase database,
    required TripApiService apiService,
    required TicketApiService ticketApiService,
    required AuthRepository authRepository,
    required StorageService storageService,
    Connectivity? connectivity,
  })  : _database = database,
        _apiService = apiService,
        _ticketApiService = ticketApiService,
        _authRepository = authRepository,
        _storageService = storageService,
        _connectivity = connectivity ?? Connectivity();

  /// Start sync service (manual sync only)
  /// 
  /// Note: Auto-sync is disabled to match conductor workflow.
  /// Conductors work offline all day and manually sync at depot.
  void start() {
    print('🔄 Starting SyncService (manual sync only)...');
    
    // AUTO-SYNC DISABLED: Conductors will manually sync at depot at end of shift
    // This prevents conflicts and allows complete offline workflow
    
    // Commented out: Listen to connectivity changes
    // _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
    //   (results) {
    //     final isOnline = results.any((result) => 
    //       result != ConnectivityResult.none
    //     );
    //     
    //     if (isOnline) {
    //       print('📡 Online - triggering sync');
    //       syncPending();
    //     } else {
    //       print('📡 Offline - skipping sync');
    //     }
    //   },
    // );
    
    // Commented out: Start periodic sync timer
    // _syncTimer = Timer.periodic(_syncInterval, (_) {
    //   syncPending();
    // });
    
    // Commented out: Initial sync attempt
    // syncPending();
    
    print('✅ SyncService ready (manual sync via UI button)');
  }

  /// Stop monitoring and cleanup
  void stop() {
    print('🛑 Stopping SyncService...');
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }

  /// Manually trigger sync
  Future<void> syncPending() async {
    if (_isSyncing) {
      print('⏭️ Sync already in progress, skipping...');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );
      
      if (!isOnline) {
        print('📡 Device offline, cannot sync');
        return;
      }
      
      print('🔄 Starting sync process...');
      
      // Ensure we have valid authentication
      final isAuthenticated = await _ensureAuthenticated();
      if (!isAuthenticated) {
        print('⚠️ Cannot sync: Authentication required');
        print('💡 User needs to login online to sync offline changes');
        return;
      }
      
      // Clean up old failed items
      await cleanupFailedItems();
      
      // Get pending sync items
      final pendingItems = await _database.getPendingSyncItems();
      
      if (pendingItems.isEmpty) {
        print('✅ No pending items to sync');
        return;
      }
      
      print('📦 Found ${pendingItems.length} items to sync');
      
      // Process each item
      for (final item in pendingItems) {
        // Skip if max retries exceeded
        if (item.retryCount >= _maxRetries) {
          print('❌ Item ${item.id} exceeded max retries, skipping');
          continue;
        }
        
        try {
          print('🔄 Syncing ${item.entityType} #${item.entityId}...');
          
          if (item.entityType == 'trip' && item.operation == 'create') {
            await _syncTripCreation(item);
          } else if (item.entityType == 'trip' && item.operation == 'end') {
            await _syncTripEnd(item);
          } else if (item.entityType == 'ticket' && item.operation == 'create') {
            await _syncTicketIssue(item);
          } else {
            print('⚠️ Unknown sync operation: ${item.entityType}/${item.operation}');
          }
          
          // Remove from queue on success
          await _database.removeSyncQueueItem(item.id);
          print('✅ Successfully synced item ${item.id}');
          
        } catch (e) {
          print('❌ Failed to sync item ${item.id}: $e');
          
          // Check for conflict errors that shouldn't be retried
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('already have an active trip')) {
            print('⚠️ Removing conflicting trip creation (active trip exists)');
            await _database.removeSyncQueueItem(item.id);
          } else {
            // Increment retry count for other errors
            await _database.incrementSyncRetry(item.id, e.toString());
          }
        }
      }
      
      print('🏁 Sync process completed');
      
    } catch (e) {
      print('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a trip creation to the backend
  Future<void> _syncTripCreation(SyncQueueData item) async {
    final data = jsonDecode(item.data) as Map<String, dynamic>;
    
    // Create trip request for API
    final request = StartTripRequest(
      routeId: data['routeId'] as String,
      fleetId: data['fleetId'] as String,
      startedOffline: true,
    );
    
    // Call API to create trip
    final response = await _apiService.startTrip(request);
    
    // Update local trip with server ID
    final localId = data['localId'] as String;
    await _database.updateTripServerId(localId, response.trip.id);
    
    print('✅ Trip synced: local=$localId, server=${response.trip.id}');
  }
  
  /// Sync a trip end to the backend
  Future<void> _syncTripEnd(SyncQueueData item) async {
    final data = jsonDecode(item.data) as Map<String, dynamic>;
    
    // Get IDs from sync data
    String? serverId = data['serverId'] as String?;
    final localId = data['localId'] as String?;
    
    // If no server ID in sync data, check database for latest state
    if ((serverId == null || serverId.isEmpty) && localId != null) {
      print('🔍 No server ID in sync data, checking database...');
      final trip = await _database.getTripByLocalId(localId);
      serverId = trip?.serverId;
    }
    
    // If still no server ID, trip creation hasn't been synced yet
    if (serverId == null || serverId.isEmpty) {
      throw Exception(
        'Cannot sync trip end yet: Trip creation not synced. '
        'Will retry after trip creation is synced.'
      );
    }
    
    // Call API to end trip
    final response = await _apiService.endTrip(serverId);
    
    print('✅ Trip end synced: server=$serverId, status=${response.trip.status}');
  }
  
  /// Sync a ticket issue to the backend
  Future<void> _syncTicketIssue(SyncQueueData item) async {
    final data = jsonDecode(item.data) as Map<String, dynamic>;
    
    // Get IDs from sync data
    final localId = data['localId'] as String;
    String? tripServerId = data['tripServerId'] as String?;
    final tripLocalId = data['tripLocalId'] as String?;
    
    // If no trip server ID but have trip local ID, check database for synced trip
    if ((tripServerId == null || tripServerId.isEmpty) && tripLocalId != null) {
      print('🔍 No trip server ID in sync data, checking database...');
      final trip = await _database.getTripByLocalId(tripLocalId);
      tripServerId = trip?.serverId;
    }
    
    // If still no trip server ID, trip creation hasn't been synced yet
    if (tripServerId == null || tripServerId.isEmpty) {
      throw Exception(
        'Cannot sync ticket yet: Trip creation not synced. '
        'Will retry after trip creation is synced.'
      );
    }
    
    // Create ticket request for API
    final request = IssueTicketRequest(
      tripId: tripServerId,
      ticketCategory: data['ticketCategory'] as String,
      currency: data['currency'] as String,
      amount: (data['amount'] as num).toDouble(),
      departure: data['departure'] as String?,
      destination: data['destination'] as String?,
      issuedAt: data['issuedAt'] != null 
          ? DateTime.parse(data['issuedAt'] as String) 
          : null,
      linkedPassengerTicketId: data['linkedPassengerTicketId'] as String?,
    );
    
    // Handle linked passenger ticket ID (for luggage tickets)
    if (request.linkedPassengerTicketId != null && 
        request.ticketCategory == TicketCategory.luggage) {
      // Check if the passenger ticket has been synced
      final passengerTicket = await _database.getTicketByLocalId(
        request.linkedPassengerTicketId!
      );
      
      if (passengerTicket == null || !passengerTicket.isSynced) {
        throw Exception(
          'Cannot sync luggage ticket yet: Passenger ticket not synced. '
          'Will retry after passenger ticket is synced.'
        );
      }
      
      // Update request with synced passenger ticket server ID
      final updatedRequest = IssueTicketRequest(
        tripId: request.tripId,
        ticketCategory: request.ticketCategory,
        currency: request.currency,
        amount: request.amount,
        departure: request.departure,
        destination: request.destination,
        issuedAt: request.issuedAt,
        linkedPassengerTicketId: passengerTicket.serverId ?? passengerTicket.localId,
      );
      
      // Call API to issue ticket
      final response = await _ticketApiService.issueTicket(updatedRequest);
      
      // Update local ticket with server ID
      await _database.markTicketAsSyncedByLocalId(
        localId,
        response.ticket.id,
        response.ticket.serialNumber?.toString(),
      );
      
      print('✅ Luggage ticket synced: local=$localId, server=${response.ticket.id}');
    } else {
      // Call API to issue ticket
      final response = await _ticketApiService.issueTicket(request);
      
      // Update local ticket with server ID
      await _database.markTicketAsSyncedByLocalId(
        localId,
        response.ticket.id,
        response.ticket.serialNumber?.toString(),
      );
      
      print('✅ Ticket synced: local=$localId, server=${response.ticket.id}');
    }
  }
  
  /// Ensure we have a valid access token for API calls
  /// If logged in offline, attempts to re-authenticate online using stored credentials
  Future<bool> _ensureAuthenticated() async {
    // Check if we have an access token
    final accessToken = await _storageService.getAccessToken();
    
    if (accessToken != null && accessToken.isNotEmpty) {
      print('✅ Access token available');
      return true;
    }
    
    // No access token - check if we have offline credentials
    final credentials = await _storageService.getOfflineCredentials();
    if (credentials == null) {
      print('❌ No credentials available for re-authentication');
      return false;
    }
    
    // Attempt to re-authenticate online
    try {
      print('🔐 Re-authenticating with stored credentials...');
      
      final merchantCode = credentials['merchant_code'] as String?;
      final agentCode = credentials['agent_code'] as String?;
      final pinHash = credentials['pin_hash'] as String?;
      
      if (merchantCode == null || agentCode == null || pinHash == null) {
        print('❌ Incomplete credentials');
        return false;
      }
      
      final response = await _authRepository.login(
        merchantCode: merchantCode,
        agentCode: agentCode,
        pin: pinHash,
      );
      
      print('✅ Re-authentication successful!');
      print('   Agent: ${response.agent.firstName} ${response.agent.lastName}');
      return true;
      
    } catch (e) {
      print('❌ Re-authentication failed: $e');
      return false;
    }
  }
  
  /// Clean up old failed items that exceeded max retries
  Future<void> cleanupFailedItems() async {
    try {
      final items = await _database.getPendingSyncItems();
      final failedItems = items.where((item) => item.retryCount >= _maxRetries);
      
      if (failedItems.isEmpty) {
        print('✅ No failed items to clean up');
        return;
      }
      
      print('🧹 Cleaning up ${failedItems.length} failed items...');
      
      for (final item in failedItems) {
        await _database.removeSyncQueueItem(item.id);
        print('   Removed item ${item.id} (${item.entityType}/${item.operation})');
      }
      
      print('✅ Cleanup completed');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final items = await _database.getPendingSyncItems();
    return items.length;
  }
}
