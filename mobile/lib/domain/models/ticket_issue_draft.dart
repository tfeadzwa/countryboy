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
    this.passengerPhone,
  });

  final TripModel trip;
  /// `PASSENGER`, `PASSENGER_WITH_LUGGAGE`, `LUGGAGE`, or `PAIR` for linked pair.
  final String mode;
  final String currency;
  final double? amount;
  final double? passengerAmount;
  final double? luggageAmount;
  final String? departure;
  final String? destination;
  final String? passengerPhone;

  bool get isPair => mode == 'PAIR';

  String get modeLabel => switch (mode) {
        'PASSENGER' => 'Passenger',
        'PASSENGER_WITH_LUGGAGE' => 'Passenger + luggage',
        'LUGGAGE' => 'Luggage only',
        'PAIR' => 'Passenger + luggage (2 tickets)',
        _ => mode,
      };

  String get routeLabel {
    if (departure != null && destination != null) {
      return '$departure -> $destination';
    }
    return trip.routeLabel;
  }

  double? get totalAmount {
    if (isPair) {
      if (passengerAmount == null || luggageAmount == null) return null;
      return passengerAmount! + luggageAmount!;
    }
    return amount;
  }
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
