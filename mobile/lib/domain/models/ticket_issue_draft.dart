import 'models.dart';

/// Ticket data collected before review and issuance.
class TicketIssueDraft {
  const TicketIssueDraft({
    required this.trip,
    required this.mode,
    required this.currency,
    this.amount,
    this.passengerAmount,
    this.luggageAmount,
    this.departure,
    this.destination,
    this.luggageDescription,
  });

  final TripModel trip;
  /// `PASSENGER`, `PASSENGER_WITH_LUGGAGE`, or `LUGGAGE`.
  final String mode;
  final String currency;
  /// Total charge stored on the ticket.
  final double? amount;
  /// Route passenger fare (PASSENGER / PASSENGER_WITH_LUGGAGE).
  final double? passengerAmount;
  /// Manually entered luggage charge (PASSENGER_WITH_LUGGAGE / LUGGAGE).
  final double? luggageAmount;
  final String? departure;
  final String? destination;
  final String? luggageDescription;

  bool get hasLuggage =>
      mode == 'PASSENGER_WITH_LUGGAGE' || mode == 'LUGGAGE';

  String get modeLabel => switch (mode) {
        'PASSENGER' => 'Passenger',
        'PASSENGER_WITH_LUGGAGE' => 'Passenger + luggage',
        'LUGGAGE' => 'Luggage only',
        _ => mode,
      };

  String get routeLabel {
    if (departure != null && destination != null) {
      return '$departure -> $destination';
    }
    return trip.routeLabel;
  }

  double? get totalAmount => amount;
}

/// Result after successful issuance, passed to the print screen.
class TicketIssueResult {
  const TicketIssueResult({
    required this.trip,
    this.single,
    this.pair,
  });

  final TripModel trip;
  final TicketModel? single;
  final PassengerLuggagePairResult? pair;

  List<TicketModel> get tickets {
    if (pair != null) return [pair!.passenger, pair!.luggage];
    if (single != null) return [single!];
    return [];
  }
}
