import 'models.dart';

/// Printable receipt payload for a single ticket.
class TicketReceiptData {
  const TicketReceiptData({
    required this.ticket,
    required this.trip,
    required this.merchantCode,
    required this.depotName,
    required this.agentName,
    required this.agentCode,
    this.deviceSerial,
  });

  final TicketModel ticket;
  final TripModel trip;
  final String merchantCode;
  final String depotName;
  final String agentName;
  final String agentCode;
  final String? deviceSerial;

  String get categoryLabel => switch (ticket.ticketCategory) {
        'PASSENGER' => 'PASSENGER',
        'PASSENGER_WITH_LUGGAGE' => 'PASSENGER + LUGGAGE',
        'LUGGAGE' => 'LUGGAGE',
        _ => ticket.ticketCategory,
      };
}
