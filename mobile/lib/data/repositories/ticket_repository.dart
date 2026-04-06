import '../api/ticket_api_service.dart';
import '../dto/ticket_dto.dart';
import '../local/database.dart';
import '../../core/storage/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

/// Ticket Repository
/// 
/// Business logic layer for ticket operations
/// Handles offline-first ticket issuing with sync queue
class TicketRepository {
  final TicketApiService _apiService;
  final AppDatabase _database;
  final StorageService _storageService;
  final Connectivity _connectivity;
  final Uuid _uuid;

  TicketRepository({
    required TicketApiService apiService,
    required AppDatabase database,
    required StorageService storageService,
    Connectivity? connectivity,
    Uuid? uuid,
  })  : _apiService = apiService,
        _database = database,
        _storageService = storageService,
        _connectivity = connectivity ?? Connectivity(),
        _uuid = uuid ?? const Uuid();

  /// Issue a single ticket (PASSENGER or LUGGAGE)
  /// 
  /// Strategy:
  /// 1. Check connectivity
  /// 2. If online, try API first
  /// 3. If offline or API fails, create locally and queue for sync
  /// 
  /// Validates:
  /// - tripId is provided
  /// - ticketCategory is PASSENGER or LUGGAGE
  /// - amount > 0
  /// - currency is valid
  /// 
  /// Returns: TicketDto
  /// Throws: Exception with user-friendly error message
  Future<TicketDto> issueTicket({
    required String tripId,
    required bool isTripLocalId,
    required String ticketCategory,
    required String currency,
    required double amount,
    String? departure,
    String? destination,
    String? linkedPassengerTicketId,
  }) async {
    // Validate inputs
    if (amount <= 0) {
      throw Exception('Ticket amount must be greater than 0');
    }
    
    if (ticketCategory != TicketCategory.passenger &&
        ticketCategory != TicketCategory.passengerWithLuggage &&
        ticketCategory != TicketCategory.luggage) {
      throw Exception('Invalid ticket category');
    }

    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    debugPrint('📡 Device is ${isOnline ? "online" : "offline"}');
    
    if (isOnline) {
      // Try API first when online
      try {
        debugPrint('🌐 Attempting online ticket issue...');
        
        // Get the server trip ID if this is a local trip
        String apiTripId = tripId;
        if (isTripLocalId) {
          final trip = await _database.getTripByLocalId(tripId);
          if (trip?.serverId != null) {
            apiTripId = trip!.serverId!;
            debugPrint('🔄 Using server trip ID: $apiTripId');
          } else {
            debugPrint('⚠️ Trip not synced yet, creating offline...');
            // Trip not synced yet, create offline
            return await _issueTicketOffline(
              tripId: tripId,
              isTripLocalId: isTripLocalId,
              ticketCategory: ticketCategory,
              currency: currency,
              amount: amount,
              departure: departure,
              destination: destination,
              linkedPassengerTicketId: linkedPassengerTicketId,
            );
          }
        }

        final request = IssueTicketRequest(
          tripId: apiTripId,
          ticketCategory: ticketCategory,
          currency: currency,
          amount: amount,
          departure: departure,
          destination: destination,
          linkedPassengerTicketId: linkedPassengerTicketId,
        );

        final response = await _apiService.issueTicket(request);
        debugPrint('✅ Ticket issued online: ${response.ticket.id}');
        return response.ticket;
      } catch (e) {
        debugPrint('⚠️ Online issue failed: $e');
        debugPrint('🔄 Falling back to offline mode...');
        // Fall through to offline creation
      }
    }
    
    // Create offline (either because offline or API failed)
    return await _issueTicketOffline(
      tripId: tripId,
      isTripLocalId: isTripLocalId,
      ticketCategory: ticketCategory,
      currency: currency,
      amount: amount,
      departure: departure,
      destination: destination,
      linkedPassengerTicketId: linkedPassengerTicketId,
    );
  }

  /// Get all tickets for a trip
  /// 
  /// Strategy:
  /// 1. Try API if online and trip has server ID
  /// 2. If API returns data, merge with local unsynced tickets
  /// 3. Always check local database to ensure offline tickets are included
  /// 
  /// Returns: List of TicketDto
  Future<List<TicketDto>> getTicketsByTrip(String tripId, bool isTripLocalId) async {
    // First, get the trip to find both local and server IDs
    Trip? trip;
    String? tripLocalId;
    String? tripServerId;
    
    try {
      if (isTripLocalId) {
        trip = await _database.getTripByLocalId(tripId);
      } else {
        trip = await _database.getTripByServerId(tripId);
      }
      
      if (trip != null) {
        tripLocalId = trip.localId;
        tripServerId = trip.serverId;
        debugPrint('📋 Found trip - LocalID: $tripLocalId, ServerID: $tripServerId');
      }
    } catch (e) {
      debugPrint('⚠️ Could not find trip: $e');
    }
    
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    // Try API first if online and trip has server ID
    List<TicketDto> apiTickets = [];
    if (isOnline && tripServerId != null) {
      try {
        debugPrint('🌐 Fetching tickets from API...');
        apiTickets = await _apiService.searchTickets(tripId: tripServerId);
        debugPrint('✅ Got ${apiTickets.length} tickets from API');
      } catch (e) {
        debugPrint('⚠️ API failed: $e');
      }
    }

    // Always check local database to get offline/unsynced tickets
    // Get current agent ID for filtering (CRITICAL for agent isolation)
    final agentData = await _storageService.getAgentData();
    if (agentData == null) {
      debugPrint('⚠️ Not authenticated');
      return []; // No tickets if not logged in
    }
    
    final agentId = agentData['id']?.toString() ?? '';
    if (agentId.isEmpty) {
      debugPrint('⚠️ Agent ID missing');
      return [];
    }
    
    final localTickets = await _database.getTicketsByTripIds(
      localId: tripLocalId ?? tripId,
      serverId: tripServerId,
      agentId: agentId,
    );
    debugPrint('📦 Got ${localTickets.length} tickets from local database for agent $agentId');
    
    // If we got API tickets, use them; otherwise use local tickets
    // In future, we could merge both and deduplicate, but for now:
    // - If API succeeded and returned tickets, prefer those (they're authoritative)
    // - But also include any local tickets that aren't in API response (unsynced)
    if (apiTickets.isNotEmpty) {
      // Merge: use API tickets + any local tickets not yet synced
      final localDto = _convertTicketsToDto(localTickets);
      final unsyncedLocal = localDto.where((local) => 
        !apiTickets.any((api) => api.id == local.id)
      ).toList();
      
      if (unsyncedLocal.isNotEmpty) {
        debugPrint('📤 Found ${unsyncedLocal.length} unsynced local tickets');
        return [...apiTickets, ...unsyncedLocal];
      }
      
      return apiTickets;
    }
    
    // No API tickets (either offline, API failed, or no tickets on server)
    // Return local tickets
    return _convertTicketsToDto(localTickets);
  }

  /// Create a ticket locally for offline operation
  Future<TicketDto> _issueTicketOffline({
    required String tripId,
    required bool isTripLocalId,
    required String ticketCategory,
    required String currency,
    required double amount,
    String? departure,
    String? destination,
    String? linkedPassengerTicketId,
  }) async {
    try {
      debugPrint('💾 Creating ticket offline...');
      
      // Get the trip to find both local and server IDs
      Trip? trip;
      String? tripLocalId;
      String? tripServerId;
      
      try {
        if (isTripLocalId) {
          trip = await _database.getTripByLocalId(tripId);
        } else {
          trip = await _database.getTripByServerId(tripId);
        }
        
        if (trip != null) {
          tripLocalId = trip.localId;
          tripServerId = trip.serverId;
          debugPrint('📋 Trip found - LocalID: $tripLocalId, ServerID: $tripServerId');
        }
      } catch (e) {
        debugPrint('⚠️ Could not find trip, using provided ID: $e');
        // Fall back to using the provided ID
        if (isTripLocalId) {
          tripLocalId = tripId;
        } else {
          tripServerId = tripId;
        }
      }
      
      final localId = _uuid.v4();
      
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
      
      final ticket = await _database.createTicketLocally(
        localId: localId,
        tripLocalId: tripLocalId ?? '',
        tripServerId: tripServerId,
        ticketCategory: ticketCategory,
        currency: currency,
        amount: amount,
        departure: departure,
        destination: destination,
        linkedPassengerTicketId: linkedPassengerTicketId,
        agentId: agentId,
        agentCode: agentCode,
      );
      
      // Queue for sync
      await _database.queueTicketIssue(ticket);
      
      debugPrint('✅ Ticket created offline: $localId');
      debugPrint('📤 Queued for sync');
      
      // Convert to DTO
      return TicketDto(
        id: ticket.localId,
        depotId: '', // Will be filled by backend
        tripId: ticket.tripServerId ?? ticket.tripLocalId ?? '',
        agentId: '', // Will be filled by backend
        ticketCategory: ticket.ticketCategory,
        currency: ticket.currency,
        amount: ticket.amount,
        departure: ticket.departure,
        destination: ticket.destination,
        linkedPassengerTicketId: ticket.linkedPassengerTicketId,
        issuedAt: ticket.issuedAt,
        createdAt: ticket.issuedAt,
        updatedAt: ticket.issuedAt,
      );
    } catch (e) {
      debugPrint('❌ Offline ticket creation failed: $e');
      throw Exception('Failed to create ticket offline: ${e.toString()}');
    }
  }

  /// Convert local Ticket entities to DTOs
  List<TicketDto> _convertTicketsToDto(List<Ticket> tickets) {
    return tickets.map((ticket) => TicketDto(
      id: ticket.serverId ?? ticket.localId,
      depotId: '',
      tripId: ticket.tripServerId ?? ticket.tripLocalId ?? '',
      agentId: '',
      serialNumber: ticket.serialNumber != null 
          ? int.tryParse(ticket.serialNumber!)
          : null,
      ticketCategory: ticket.ticketCategory,
      currency: ticket.currency,
      amount: ticket.amount,
      departure: ticket.departure,
      destination: ticket.destination,
      linkedPassengerTicketId: ticket.linkedPassengerTicketId,
      issuedAt: ticket.issuedAt,
      createdAt: ticket.issuedAt,
      updatedAt: ticket.issuedAt,
    )).toList();
  }
}
