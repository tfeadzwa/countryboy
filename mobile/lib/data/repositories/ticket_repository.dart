import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/models/models.dart';
import '../../services/sync_service.dart';
import '../api/api_services.dart';
import '../local/database.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(
    api: ref.watch(ticketApiProvider),
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

class TicketRepository {
  TicketRepository({
    required TicketApi api,
    required AppDatabase db,
    required SecureStorageService storage,
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _api = api,
        _db = db,
        _storage = storage,
        _connectivity = connectivity,
        _sync = syncService;

  final TicketApi _api;
  final AppDatabase _db;
  final SecureStorageService _storage;
  final ConnectivityService _connectivity;
  final SyncService _sync;

  Future<TicketModel> issueTicket({
    required String tripId,
    required String ticketCategory,
    required String currency,
    required double amount,
    String? departure,
    String? destination,
    required String idempotencyKey,
    String? linkedPassengerTicketId,
    String? passengerName,
    String? passengerPhone,
  }) async {
    if (await _db.ticketExistsByIdempotencyKey(idempotencyKey)) {
      final existing = await (_db.select(_db.localTickets)
            ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
          .getSingle();
      return _mapLocal(existing);
    }

    final agentJson = await _storage.getAgentProfile();
    final depotId = await _storage.getDepotId();
    final deviceId = await _storage.getDeviceId();
    if (agentJson == null || depotId == null) {
      throw ApiError(message: 'Session expired. Please sign in again.');
    }

    var ticketId = _sync.generateId();
    final issuedAt = DateTime.now();
    final offline = !(await _connectivity.checkReachability());

    await _db.insertTicket(
      LocalTicketsCompanion.insert(
        id: ticketId,
        tripId: tripId,
        agentId: agentJson['id'] as String,
        deviceId: Value(deviceId),
        depotId: depotId,
        ticketCategory: ticketCategory,
        currency: currency,
        amount: amount,
        departure: Value(departure),
        destination: Value(destination),
        passengerName: Value(passengerName),
        passengerPhone: Value(passengerPhone),
        issuedAt: issuedAt,
        syncStatus: const Value('pending'),
        idempotencyKey: idempotencyKey,
      ),
    );

    if (offline) {
      await _enqueueTicket(
        ticketId,
        tripId,
        ticketCategory,
        currency,
        amount,
        departure,
        destination,
        issuedAt,
        deviceId,
        depotId,
        agentJson['id'] as String,
        linkedPassengerTicketId,
        passengerName,
        passengerPhone,
      );
      _sync.syncIfOnline();
      return _mapLocal(
        await (_db.select(_db.localTickets)..where((t) => t.id.equals(ticketId)))
            .getSingle(),
      );
    }

    try {
      final result = await _api.issueTicket(
        tripId: tripId,
        ticketCategory: ticketCategory,
        currency: currency,
        amount: amount,
        deviceId: deviceId,
        departure: departure,
        destination: destination,
        issuedAt: issuedAt,
        linkedPassengerTicketId: linkedPassengerTicketId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
      );
      final serverId = result['id'] as String;
      if (serverId != ticketId) {
        await (_db.delete(_db.localTickets)..where((t) => t.id.equals(ticketId))).go();
        await _db.insertTicket(
          LocalTicketsCompanion.insert(
            id: serverId,
            tripId: tripId,
            agentId: agentJson['id'] as String,
            deviceId: Value(deviceId),
            depotId: depotId,
            ticketCategory: ticketCategory,
            currency: currency,
            amount: amount,
            departure: Value(departure),
            destination: Value(destination),
            passengerName: Value(passengerName),
            passengerPhone: Value(passengerPhone),
            issuedAt: issuedAt,
            syncStatus: const Value('synced'),
            idempotencyKey: idempotencyKey,
            serialNumber: Value(result['serial_number'] as int?),
          ),
        );
        ticketId = serverId;
      } else {
        await _db.updateTicketSyncStatus(
          ticketId,
          'synced',
          serialNumber: result['serial_number'] as int?,
        );
      }
      return TicketModel(
        id: ticketId,
        tripId: tripId,
        ticketCategory: ticketCategory,
        currency: currency,
        amount: amount,
        departure: departure,
        destination: destination,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        serialNumber: result['serial_number'] as int?,
        issuedAt: issuedAt,
        syncStatus: 'synced',
      );
    } catch (_) {
      await _db.updateTicketSyncStatus(ticketId, 'pending');
      await _enqueueTicket(
        ticketId,
        tripId,
        ticketCategory,
        currency,
        amount,
        departure,
        destination,
        issuedAt,
        deviceId,
        depotId,
        agentJson['id'] as String,
        linkedPassengerTicketId,
        passengerName,
        passengerPhone,
      );
      _sync.syncIfOnline();
      return _mapLocal(
        await (_db.select(_db.localTickets)..where((t) => t.id.equals(ticketId)))
            .getSingle(),
      );
    }
  }

  Future<PassengerLuggagePairResult> issuePassengerLuggagePair({
    required String tripId,
    required String currency,
    required double passengerAmount,
    required double luggageAmount,
    required String passengerName,
    required String passengerPhone,
    String? departure,
    String? destination,
    required String idempotencyKey,
  }) async {
    if (passengerAmount <= 0 || luggageAmount <= 0) {
      throw ApiError(message: 'Enter valid amounts for passenger and luggage.');
    }

    final passenger = await issueTicket(
      tripId: tripId,
      ticketCategory: 'PASSENGER',
      currency: currency,
      amount: passengerAmount,
      departure: departure,
      destination: destination,
      idempotencyKey: '$idempotencyKey-passenger',
      passengerName: passengerName,
      passengerPhone: passengerPhone,
    );

    final luggage = await issueTicket(
      tripId: tripId,
      ticketCategory: 'LUGGAGE',
      currency: currency,
      amount: luggageAmount,
      departure: departure,
      destination: destination,
      idempotencyKey: '$idempotencyKey-luggage',
      linkedPassengerTicketId: passenger.id,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
    );

    return PassengerLuggagePairResult(passenger: passenger, luggage: luggage);
  }

  Future<({int count, double revenue, String currency})> getTripStats(
    String tripId,
  ) async {
    final tickets = await _db.getAllTickets(tripId: tripId);
    final revenue = tickets.fold<double>(0, (sum, t) => sum + t.amount);
    return (
      count: tickets.length,
      revenue: revenue,
      currency: tickets.isNotEmpty ? tickets.first.currency : 'USD',
    );
  }

  Future<void> _enqueueTicket(
    String ticketId,
    String tripId,
    String category,
    String currency,
    double amount,
    String? departure,
    String? destination,
    DateTime issuedAt,
    String? deviceId,
    String depotId,
    String agentId,
    String? linkedPassengerTicketId,
    String? passengerName,
    String? passengerPhone,
  ) async {
    await _db.enqueueSync(
      SyncQueueItemsCompanion.insert(
        entityType: 'ticket',
        entityId: ticketId,
        operation: 'CREATE_TICKET',
        payloadJson: jsonEncode({
          'id': ticketId,
          'depot_id': depotId,
          'trip_id': tripId,
          'agent_id': agentId,
          'device_id': deviceId,
          'ticket_category': category,
          'currency': currency,
          'amount': amount,
          'departure': departure,
          'destination': destination,
          'issued_at': issuedAt.toUtc().toIso8601String(),
          if (linkedPassengerTicketId != null)
            'linked_passenger_ticket_id': linkedPassengerTicketId,
          if (passengerName != null) 'passenger_name': passengerName,
          if (passengerPhone != null) 'passenger_phone': passengerPhone,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> syncTicketToServer(Map<String, dynamic> payload) async {
    // Handled by SyncService via /sync/push
    await _db.updateTicketSyncStatus(payload['id'] as String, 'synced');
  }

  Future<List<TicketModel>> getTickets({String? tripId}) async {
    final rows = await _db.getAllTickets(tripId: tripId);
    return rows.map(_mapLocal).toList();
  }

  Future<List<TicketModel>> getTodayTickets() async {
    final rows = await _db.getTicketsForToday();
    return rows.map(_mapLocal).toList();
  }

  Future<int> countPending() => _db.countPendingTickets();

  TicketModel _mapLocal(LocalTicket t) => TicketModel(
        id: t.id,
        tripId: t.tripId,
        ticketCategory: t.ticketCategory,
        currency: t.currency,
        amount: t.amount,
        departure: t.departure,
        destination: t.destination,
        passengerName: t.passengerName,
        passengerPhone: t.passengerPhone,
        serialNumber: t.serialNumber,
        issuedAt: t.issuedAt,
        syncStatus: t.syncStatus,
        lastError: t.lastError,
        retryCount: t.retryCount,
      );
}
