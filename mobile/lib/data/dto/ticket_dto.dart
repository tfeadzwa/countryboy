/// Ticket Data Transfer Objects
/// 
/// Handles serialization/deserialization for ticket-related API requests and responses

/// Request to issue a single ticket (PASSENGER or LUGGAGE)
class IssueTicketRequest {
  final String tripId;
  final String? agentId; // Optional, backend can use JWT
  final String? deviceId;
  final String ticketCategory; // PASSENGER, LUGGAGE
  final String currency; // ZWL, USD
  final double amount;
  final String? departure;
  final String? destination;
  final DateTime? issuedAt;
  final String? linkedPassengerTicketId; // For LUGGAGE tickets

  IssueTicketRequest({
    required this.tripId,
    this.agentId,
    this.deviceId,
    required this.ticketCategory,
    required this.currency,
    required this.amount,
    this.departure,
    this.destination,
    this.issuedAt,
    this.linkedPassengerTicketId,
  });

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        if (agentId != null) 'agent_id': agentId,
        if (deviceId != null) 'device_id': deviceId,
        'ticket_category': ticketCategory,
        'currency': currency,
        'amount': amount,
        if (departure != null) 'departure': departure,
        if (destination != null) 'destination': destination,
        if (issuedAt != null) 'issued_at': issuedAt!.toIso8601String(),
        if (linkedPassengerTicketId != null)
          'linked_passenger_ticket_id': linkedPassengerTicketId,
      };
}

/// Response when issuing a single ticket
class IssueTicketResponse {
  final TicketDto ticket;

  IssueTicketResponse({required this.ticket});

  factory IssueTicketResponse.fromJson(Map<String, dynamic> json) =>
      IssueTicketResponse(
        ticket: TicketDto.fromJson(json),
      );
}

/// Ticket data transfer object
class TicketDto {
  final String id;
  final String depotId;
  final String tripId;
  final String agentId;
  final String? deviceId;
  final int? serialNumber;
  final String ticketCategory;
  final String currency;
  final double amount;
  final String? departure;
  final String? destination;
  final String? linkedPassengerTicketId;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketDto({
    required this.id,
    required this.depotId,
    required this.tripId,
    required this.agentId,
    this.deviceId,
    this.serialNumber,
    required this.ticketCategory,
    required this.currency,
    required this.amount,
    this.departure,
    this.destination,
    this.linkedPassengerTicketId,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) => TicketDto(
        id: json['id'] as String,
        depotId: json['depot_id'] as String,
        tripId: json['trip_id'] as String,
        agentId: json['agent_id'] as String,
        deviceId: json['device_id'] as String?,
        serialNumber: json['serial_number'] as int?,
        ticketCategory: json['ticket_category'] as String,
        currency: json['currency'] as String,
        amount: (json['amount'] as num).toDouble(),
        departure: json['departure'] as String?,
        destination: json['destination'] as String?,
        linkedPassengerTicketId: json['linked_passenger_ticket_id'] as String?,
        issuedAt: DateTime.parse(json['issued_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'depot_id': depotId,
        'trip_id': tripId,
        'agent_id': agentId,
        if (deviceId != null) 'device_id': deviceId,
        if (serialNumber != null) 'serial_number': serialNumber,
        'ticket_category': ticketCategory,
        'currency': currency,
        'amount': amount,
        if (departure != null) 'departure': departure,
        if (destination != null) 'destination': destination,
        if (linkedPassengerTicketId != null)
          'linked_passenger_ticket_id': linkedPassengerTicketId,
        'issued_at': issuedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Ticket categories
class TicketCategory {
  static const String passenger = 'PASSENGER';
  static const String passengerWithLuggage = 'PASSENGER_WITH_LUGGAGE';
  static const String luggage = 'LUGGAGE';
}

/// Common currencies used in the system
class Currency {
  static const String zwl = 'ZWL';
  static const String usd = 'USD';
}
