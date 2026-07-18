import 'package:equatable/equatable.dart';

class AgentProfile extends Equatable {
  const AgentProfile({
    required this.id,
    required this.agentCode,
    required this.firstName,
    required this.lastName,
    required this.merchantCode,
    required this.merchantName,
    required this.depotName,
    this.depotId,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    String readString(String snake, [String? camel]) {
      final value = json[snake] ?? (camel != null ? json[camel] : null);
      if (value == null) return '';
      return value.toString();
    }

    return AgentProfile(
      id: readString('id'),
      agentCode: readString('agent_code', 'agentCode'),
      firstName: readString('first_name', 'firstName'),
      lastName: readString('last_name', 'lastName'),
      merchantCode: readString('merchant_code', 'merchantCode').isNotEmpty
          ? readString('merchant_code', 'merchantCode')
          : readString('depot_code', 'depotCode'),
      merchantName: readString('merchant_name', 'merchantName'),
      depotName: readString('depot_name', 'depotName'),
      depotId: () {
        final value = json['depot_id'] ?? json['depotId'];
        if (value == null) return null;
        final text = value.toString();
        return text.isEmpty ? null : text;
      }(),
    );
  }

  final String id;
  final String agentCode;
  final String firstName;
  final String lastName;
  final String merchantCode;
  final String merchantName;
  final String depotName;
  final String? depotId;

  String get fullName {
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agent_code': agentCode,
        'first_name': firstName,
        'last_name': lastName,
        'merchant_code': merchantCode,
        'merchant_name': merchantName,
        'depot_name': depotName,
        if (depotId != null) 'depot_id': depotId,
      };

  @override
  List<Object?> get props => [
        id,
        agentCode,
        firstName,
        lastName,
        merchantCode,
        merchantName,
        depotName,
        depotId,
      ];
}

class LoginResult extends Equatable {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.agent,
  });

  final String accessToken;
  final String refreshToken;
  final AgentProfile agent;

  @override
  List<Object?> get props => [accessToken, refreshToken, agent];
}

class PairDeviceResult extends Equatable {
  const PairDeviceResult({
    required this.deviceId,
    required this.deviceToken,
    required this.depotId,
    required this.serialNumber,
    required this.merchantCode,
    this.depotName,
  });

  factory PairDeviceResult.fromJson(Map<String, dynamic> json) {
    return PairDeviceResult(
      deviceId: json['device_id'] as String,
      deviceToken: json['device_token'] as String,
      depotId: json['depot_id'] as String,
      serialNumber: json['serial_number'] as String,
      merchantCode: json['merchant_code'] as String,
      depotName: json['depot_name'] as String?,
    );
  }

  final String deviceId;
  final String deviceToken;
  final String depotId;
  final String serialNumber;
  final String merchantCode;
  final String? depotName;

  @override
  List<Object?> get props =>
      [deviceId, deviceToken, depotId, serialNumber, merchantCode, depotName];
}

class FleetModel extends Equatable {
  const FleetModel({required this.id, required this.number, this.status});

  factory FleetModel.fromJson(Map<String, dynamic> json) => FleetModel(
        id: json['id'] as String,
        number: json['number'] as String,
        status: json['status'] as String?,
      );

  final String id;
  final String number;
  final String? status;

  @override
  List<Object?> get props => [id, number, status];
}

class RouteModel extends Equatable {
  const RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    this.parentRouteIds = const [],
    this.parentRouteLabels = const [],
    this.childRouteIds = const [],
    this.embeddedChildren = const [],
    this.isActive = true,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final parentIds = (json['parent_route_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['parent_route_id'] != null
            ? [json['parent_route_id'] as String]
            : <String>[]);
    final parentLabels = (json['parent_route_labels'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['parent_route_label'] != null
            ? [json['parent_route_label'] as String]
            : <String>[]);
    final childIds = (json['child_route_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final embeddedChildren = (json['child_routes'] as List?)
            ?.map((e) => RouteModel.fromSummary(e as Map<String, dynamic>))
            .toList() ??
        const <RouteModel>[];
    final resolvedChildIds = childIds.isNotEmpty
        ? childIds
        : embeddedChildren.map((r) => r.id).toList();

    return RouteModel(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      parentRouteIds: parentIds,
      parentRouteLabels: parentLabels,
      childRouteIds: resolvedChildIds,
      embeddedChildren: embeddedChildren,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  factory RouteModel.fromSummary(Map<String, dynamic> json) => RouteModel(
        id: json['id'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        isActive: json['is_active'] as bool? ?? true,
      );

  final String id;
  final String origin;
  final String destination;
  final List<String> parentRouteIds;
  final List<String> parentRouteLabels;
  final List<String> childRouteIds;
  final List<RouteModel> embeddedChildren;
  final bool isActive;

  String get label => '$origin -> $destination';
  bool get hasParents => parentRouteIds.isNotEmpty;
  bool get hasChildren => childRouteIds.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        origin,
        destination,
        parentRouteIds,
        parentRouteLabels,
        childRouteIds,
        embeddedChildren,
        isActive,
      ];
}

class FareModel extends Equatable {
  const FareModel({
    required this.id,
    required this.routeId,
    required this.currency,
    required this.amount,
    this.routeLabel,
  });

  factory FareModel.fromJson(Map<String, dynamic> json) => FareModel(
        id: json['id'] as String,
        routeId: json['route_id'] as String,
        currency: json['currency'] as String,
        amount: double.parse(json['amount'].toString()),
        routeLabel: json['route_label'] as String?,
      );

  final String id;
  final String routeId;
  final String currency;
  final double amount;
  final String? routeLabel;

  @override
  List<Object?> get props => [id, routeId, currency, amount, routeLabel];
}

class TripModel extends Equatable {
  const TripModel({
    required this.id,
    required this.agentId,
    required this.fleetId,
    required this.routeId,
    required this.status,
    required this.startedAt,
    this.deviceId,
    this.fleetNumber,
    this.routeOrigin,
    this.routeDestination,
    this.ticketsCount = 0,
    this.totalRevenue = 0,
    this.syncStatus = 'synced',
  });

  final String id;
  final String agentId;
  final String fleetId;
  final String routeId;
  final String? deviceId;
  final String status;
  final DateTime startedAt;
  final String? fleetNumber;
  final String? routeOrigin;
  final String? routeDestination;
  final int ticketsCount;
  final double totalRevenue;
  final String syncStatus;

  String get routeLabel {
    if (routeOrigin != null && routeDestination != null) {
      return '$routeOrigin -> $routeDestination';
    }
    return 'Route';
  }

  bool get isActive => status == 'ACTIVE';

  TripModel copyWith({
    int? ticketsCount,
    double? totalRevenue,
    String? syncStatus,
  }) =>
      TripModel(
        id: id,
        agentId: agentId,
        fleetId: fleetId,
        routeId: routeId,
        deviceId: deviceId,
        status: status,
        startedAt: startedAt,
        fleetNumber: fleetNumber,
        routeOrigin: routeOrigin,
        routeDestination: routeDestination,
        ticketsCount: ticketsCount ?? this.ticketsCount,
        totalRevenue: totalRevenue ?? this.totalRevenue,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  @override
  List<Object?> get props => [id, agentId, status];
}

class TicketModel extends Equatable {
  const TicketModel({
    required this.id,
    required this.tripId,
    required this.ticketCategory,
    required this.currency,
    required this.amount,
    required this.issuedAt,
    this.departure,
    this.destination,
    this.passengerName,
    this.passengerPhone,
    this.serialNumber,
    this.syncStatus = 'pending',
    this.lastError,
    this.retryCount = 0,
  });

  final String id;
  final String tripId;
  final String ticketCategory;
  final String currency;
  final double amount;
  final String? departure;
  final String? destination;
  final String? passengerName;
  final String? passengerPhone;
  final int? serialNumber;
  final DateTime issuedAt;
  final String syncStatus;
  final String? lastError;
  final int retryCount;

  String get displayNumber =>
      serialNumber != null
          ? serialNumber!.toString().padLeft(3, '0')
          : 'Pending';

  String get routeLabel {
    if (departure != null && destination != null) {
      return '$departure -> $destination';
    }
    return '-';
  }

  String get passengerLabel {
    if (passengerPhone != null && passengerPhone!.isNotEmpty) {
      return passengerPhone!;
    }
    return '-';
  }

  @override
  List<Object?> get props => [id, tripId, ticketCategory, amount, syncStatus];
}

class PassengerLuggagePairResult extends Equatable {
  const PassengerLuggagePairResult({
    required this.passenger,
    required this.luggage,
  });

  final TicketModel passenger;
  final TicketModel luggage;

  @override
  List<Object?> get props => [passenger, luggage];
}

class TripEndSummary extends Equatable {
  const TripEndSummary({
    required this.tripId,
    required this.routeLabel,
    required this.fleetNumber,
    required this.startedAt,
    required this.endedAt,
    required this.totalTickets,
    required this.totalRevenue,
    required this.currency,
    required this.syncStatus,
  });

  final String tripId;
  final String routeLabel;
  final String fleetNumber;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalTickets;
  final double totalRevenue;
  final String currency;
  final String syncStatus;

  Duration get duration => endedAt.difference(startedAt);

  @override
  List<Object?> get props =>
      [tripId, totalTickets, totalRevenue, syncStatus];
}
