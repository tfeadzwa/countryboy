import 'dart:convert';

import 'package:intl/intl.dart';

import '../../data/local/database.dart';

/// Conductor-facing view of one sync queue row (resolved from local DB / payload).
class SyncQueueDisplayItem {
  const SyncQueueDisplayItem({
    required this.item,
    required this.title,
    required this.isTrip,
    this.routeLabel,
    this.detailLine,
  });

  final SyncQueueItem item;
  final String title;
  final bool isTrip;

  /// e.g. "Beitbridge → Harare"
  final String? routeLabel;

  /// e.g. "Passenger · USD 25.00 · 12:20 PM" or "Fleet 12 · John Moyo"
  final String? detailLine;

  bool get isFailed => item.status == 'failed';
}

/// Builds readable sync rows by joining queue items with local tickets/trips.
Future<List<SyncQueueDisplayItem>> buildSyncQueueDisplayItems(
  AppDatabase db,
  List<SyncQueueItem> items,
) async {
  final ticketIds = items
      .where((i) => i.entityType == 'ticket')
      .map((i) => i.entityId)
      .toSet();
  final tripIds = <String>{
    ...items.where((i) => i.entityType == 'trip').map((i) => i.entityId),
  };

  final ticketsById = <String, LocalTicket>{};
  for (final id in ticketIds) {
    final ticket = await db.getTicketById(id);
    if (ticket != null) {
      ticketsById[id] = ticket;
      tripIds.add(ticket.tripId);
    }
  }

  // Also pick trip ids from ticket payloads when the local ticket row is gone.
  for (final item in items) {
    if (item.entityType != 'ticket') continue;
    if (ticketsById.containsKey(item.entityId)) continue;
    final payload = _decodePayload(item.payloadJson);
    final tripId = payload['trip_id'] as String?;
    if (tripId != null && tripId.isNotEmpty) tripIds.add(tripId);
  }

  final tripsById = <String, LocalTrip>{};
  for (final id in tripIds) {
    final trip = await db.getTripById(id);
    if (trip != null) tripsById[id] = trip;
  }

  return items
      .map((item) => _mapItem(item, ticketsById, tripsById))
      .toList(growable: false);
}

SyncQueueDisplayItem _mapItem(
  SyncQueueItem item,
  Map<String, LocalTicket> ticketsById,
  Map<String, LocalTrip> tripsById,
) {
  final payload = _decodePayload(item.payloadJson);

  if (item.entityType == 'ticket') {
    return _mapTicket(item, payload, ticketsById, tripsById);
  }
  if (item.entityType == 'trip') {
    return _mapTrip(item, payload, tripsById);
  }

  return SyncQueueDisplayItem(
    item: item,
    title: _fallbackTitle(item),
    isTrip: false,
    detailLine: _timeLabel(item.createdAt),
  );
}

SyncQueueDisplayItem _mapTicket(
  SyncQueueItem item,
  Map<String, dynamic> payload,
  Map<String, LocalTicket> ticketsById,
  Map<String, LocalTrip> tripsById,
) {
  final ticket = ticketsById[item.entityId];
  final tripId =
      ticket?.tripId ?? (payload['trip_id'] as String?) ?? '';
  final trip = tripId.isNotEmpty ? tripsById[tripId] : null;

  final departure = _stringOrNull(ticket?.departure) ??
      _stringOrNull(payload['departure'] as String?);
  final destination = _stringOrNull(ticket?.destination) ??
      _stringOrNull(payload['destination'] as String?);
  final routeLabel = _routeLabel(
        departure,
        destination,
      ) ??
      _routeLabel(trip?.routeOrigin, trip?.routeDestination);

  final category = ticket?.ticketCategory ??
      (payload['ticket_category'] as String?) ??
      'PASSENGER';
  final currency =
      ticket?.currency ?? (payload['currency'] as String?) ?? 'USD';
  final amount = ticket?.amount ?? _asDouble(payload['amount']) ?? 0;
  final serial = ticket?.serialNumber ?? _asInt(payload['serial_number']);
  final issuedAt = ticket?.issuedAt ??
      DateTime.tryParse(payload['issued_at'] as String? ?? '')?.toLocal() ??
      item.createdAt;

  final detailParts = <String>[
    _categoryLabel(category),
    '$currency ${amount.toStringAsFixed(2)}',
    if (serial != null) '#$serial',
    _timeLabel(issuedAt),
  ];

  return SyncQueueDisplayItem(
    item: item,
    title: switch (item.operation) {
      'MARK_TICKET_PRINTED' => 'Ticket printed',
      _ => 'New ticket',
    },
    isTrip: false,
    routeLabel: routeLabel,
    detailLine: detailParts.join(' · '),
  );
}

SyncQueueDisplayItem _mapTrip(
  SyncQueueItem item,
  Map<String, dynamic> payload,
  Map<String, LocalTrip> tripsById,
) {
  final trip = tripsById[item.entityId];
  final origin = _stringOrNull(trip?.routeOrigin) ??
      _stringOrNull(payload['origin'] as String?);
  final destination = _stringOrNull(trip?.routeDestination) ??
      _stringOrNull(payload['destination'] as String?);
  final routeLabel = _routeLabel(origin, destination);

  final fleetNumber = _stringOrNull(trip?.fleetNumber);
  final registration = _stringOrNull(trip?.fleetRegistrationNumber);
  final driverName = _stringOrNull(trip?.driverName);
  final when = trip?.startedAt ??
      DateTime.tryParse(payload['started_at'] as String? ?? '')?.toLocal() ??
      item.createdAt;

  final fleetLabel = [
    if (fleetNumber != null) 'Fleet $fleetNumber',
    if (registration != null) registration,
  ].join(' · ');

  final detailParts = <String>[
    if (fleetLabel.isNotEmpty) fleetLabel,
    if (driverName != null) driverName,
    _timeLabel(when),
  ];

  return SyncQueueDisplayItem(
    item: item,
    title: switch (item.operation) {
      'END_TRIP' => 'Trip ended',
      _ => 'Trip started',
    },
    isTrip: true,
    routeLabel: routeLabel,
    detailLine: detailParts.isEmpty ? null : detailParts.join(' · '),
  );
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return const {};
}

String _fallbackTitle(SyncQueueItem item) {
  final type = switch (item.entityType) {
    'trip' => 'Trip',
    'ticket' => 'Ticket',
    _ => item.entityType,
  };
  final op = item.operation.replaceAll('_', ' ').toLowerCase();
  return '$type · $op';
}

String? _routeLabel(String? origin, String? destination) {
  final from = _stringOrNull(origin);
  final to = _stringOrNull(destination);
  if (from == null && to == null) return null;
  if (from != null && to != null) return '$from → $to';
  return from ?? to;
}

String _categoryLabel(String category) => switch (category) {
      'PASSENGER' => 'Passenger',
      'PASSENGER_WITH_LUGGAGE' => 'Passenger + luggage',
      'LUGGAGE' => 'Luggage',
      _ => category,
    };

String? _stringOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _timeLabel(DateTime value) =>
    DateFormat.MMMd().add_jm().format(value.toLocal());
