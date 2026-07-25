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

  Future<int> _nextTripSerial(String tripId) async {
    final tickets = await _db.getAllTickets(tripId: tripId);
    var max = 0;
    for (final ticket in tickets) {
      final serial = ticket.serialNumber;
      if (serial != null && serial > max) {
        max = serial;
      }
    }
    return max + 1;
  }

  Future<TicketModel> issueTicket({
    required String tripId,
    required String ticketCategory,
    required String currency,
    required double amount,
    required String departure,
    required String destination,
    required String idempotencyKey,
    String? linkedPassengerTicketId,
    String? passengerPhone,
    double? luggageAmount,
    String? luggageDescription,
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

    final trip = await _db.getTripById(tripId);
    if (trip == null) {
      throw ApiError(message: 'Trip not found on this device.');
    }
    if (trip.status != 'ACTIVE') {
      throw ApiError(
        message:
            'This trip is closed. Ask the cashier if you need a new trip started.',
      );
    }

    // Online: re-check server so cashier-ended trips cannot keep issuing.
    if (await _connectivity.checkReachability() &&
        await _storage.hasOnlineAuth()) {
      try {
        await _sync.reconcileActiveTrip();
      } catch (_) {}
      final refreshed = await _db.getTripById(tripId);
      if (refreshed == null || refreshed.status != 'ACTIVE') {
        throw ApiError(
          message:
              'This trip was closed by the depot. Start a new trip to sell tickets.',
        );
      }
      final agentId = agentJson['id']?.toString();
      if (agentId != null) {
        final active = await _db.getActiveTrip(agentId);
        if (active == null || active.id != tripId) {
          throw ApiError(
            message:
                'This trip was closed by the depot. Start a new trip to sell tickets.',
          );
        }
      }
    }

    final phone = passengerPhone?.trim().isEmpty == true
        ? null
        : passengerPhone?.trim();
    final luggageNote = luggageDescription?.trim().isEmpty == true
        ? null
        : luggageDescription?.trim();
    final luggageCharge =
        luggageAmount != null && luggageAmount > 0 ? luggageAmount : null;

    var ticketId = _sync.generateId();
    final issuedAt = DateTime.now();
    final offline = !(await _connectivity.checkReachability());
    final tripSerial = offline ? await _nextTripSerial(tripId) : null;

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
        passengerPhone: Value(phone),
        luggageAmount: Value(luggageCharge),
        luggageDescription: Value(luggageNote),
        issuedAt: issuedAt,
        syncStatus: const Value('pending'),
        idempotencyKey: idempotencyKey,
        serialNumber: tripSerial != null ? Value(tripSerial) : const Value.absent(),
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
        phone,
        luggageCharge,
        luggageNote,
        tripSerial!,
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
        passengerPhone: phone,
        luggageAmount: luggageCharge,
        luggageDescription: luggageNote,
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
            passengerPhone: Value(phone),
            luggageAmount: Value(luggageCharge),
            luggageDescription: Value(luggageNote),
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
        passengerPhone: phone,
        luggageAmount: luggageCharge,
        luggageDescription: luggageNote,
        serialNumber: result['serial_number'] as int?,
        issuedAt: issuedAt,
        syncStatus: 'synced',
      );
    } catch (_) {
      final fallbackSerial = await _nextTripSerial(tripId);
      await (_db.update(_db.localTickets)..where((t) => t.id.equals(ticketId))).write(
        LocalTicketsCompanion(serialNumber: Value(fallbackSerial)),
      );
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
        phone,
        luggageCharge,
        luggageNote,
        fallbackSerial,
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
    required String departure,
    required String destination,
    String? passengerPhone,
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
      passengerPhone: passengerPhone,
      luggageAmount: luggageAmount,
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
    String? passengerPhone,
    double? luggageAmount,
    String? luggageDescription,
    int? serialNumber,
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
          if (serialNumber != null) 'serial_number': serialNumber,
          if (linkedPassengerTicketId != null)
            'linked_passenger_ticket_id': linkedPassengerTicketId,
          if (passengerPhone != null) 'passenger_phone': passengerPhone,
          if (luggageAmount != null) 'luggage_amount': luggageAmount,
          if (luggageDescription != null)
            'luggage_description': luggageDescription,
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
        luggageAmount: t.luggageAmount,
        luggageDescription: t.luggageDescription,
        serialNumber: t.serialNumber,
        issuedAt: t.issuedAt,
        printed: t.printed,
        printedAt: t.printedAt,
        syncStatus: t.syncStatus,
        lastError: t.lastError,
        retryCount: t.retryCount,
      );

  /// Marks tickets as successfully printed on the thermal printer.
  Future<void> markTicketsPrinted(List<String> ticketIds) async {
    final ids = ticketIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;

    final printedAt = DateTime.now();
    await _db.markTicketsPrinted(ids, printedAt: printedAt);

    final printerName = await _storage.getPrinterName();
    final printerMac = await _storage.getPrinterMac();
    final printerSerial = await _storage.getPrinterSerial();

    for (final id in ids) {
      final ticket = await _db.getTicketById(id);
      if (ticket == null) continue;
      await _db.enqueueSync(
        SyncQueueItemsCompanion.insert(
          entityType: 'ticket',
          entityId: id,
          operation: 'MARK_TICKET_PRINTED',
          payloadJson: jsonEncode({
            'id': id,
            'depot_id': ticket.depotId,
            'trip_id': ticket.tripId,
            'agent_id': ticket.agentId,
            'device_id': ticket.deviceId,
            'ticket_category': ticket.ticketCategory,
            'currency': ticket.currency,
            'amount': ticket.amount,
            'departure': ticket.departure,
            'destination': ticket.destination,
            'issued_at': ticket.issuedAt.toUtc().toIso8601String(),
            if (ticket.serialNumber != null)
              'serial_number': ticket.serialNumber,
            if (ticket.passengerPhone != null)
              'passenger_phone': ticket.passengerPhone,
            if (ticket.luggageAmount != null)
              'luggage_amount': ticket.luggageAmount,
            if (ticket.luggageDescription != null)
              'luggage_description': ticket.luggageDescription,
            'printed': true,
            'printed_at': printedAt.toUtc().toIso8601String(),
            if (printerName != null && printerName.isNotEmpty)
              'printer_name': printerName,
            if (printerMac != null && printerMac.isNotEmpty)
              'printer_mac': printerMac,
            if (printerSerial != null && printerSerial.isNotEmpty)
              'printer_serial': printerSerial,
          }),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    _sync.syncIfOnline();
  }

  Future<TicketModel?> getTicketById(String id) async {
    final row = await _db.getTicketById(id);
    return row == null ? null : _mapLocal(row);
  }
}
