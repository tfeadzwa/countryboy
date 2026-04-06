/// Trip Data Transfer Objects
/// 
/// Handles serialization/deserialization for trip-related API requests and responses

/// Request to start a new trip
class StartTripRequest {
  final String fleetId;
  final String routeId;
  final String? deviceId;
  final bool? startedOffline;

  StartTripRequest({
    required this.fleetId,
    required this.routeId,
    this.deviceId,
    this.startedOffline,
  });

  Map<String, dynamic> toJson() => {
        'fleet_id': fleetId,
        'route_id': routeId,
        if (deviceId != null) 'device_id': deviceId,
        if (startedOffline != null) 'started_offline': startedOffline,
      };
}

/// Response when starting a trip
class StartTripResponse {
  final String message;
  final TripDto trip;

  StartTripResponse({
    required this.message,
    required this.trip,
  });

  factory StartTripResponse.fromJson(Map<String, dynamic> json) =>
      StartTripResponse(
        message: json['message'] as String,
        trip: TripDto.fromJson(json['trip'] as Map<String, dynamic>),
      );
}

/// Response when ending a trip
class EndTripResponse {
  final String message;
  final TripDto trip;

  EndTripResponse({
    required this.message,
    required this.trip,
  });

  factory EndTripResponse.fromJson(Map<String, dynamic> json) =>
      EndTripResponse(
        message: json['message'] as String,
        trip: TripDto.fromJson(json['trip'] as Map<String, dynamic>),
      );
}

/// Response when getting active trip
class ActiveTripResponse {
  final TripDto? trip;

  ActiveTripResponse({this.trip});

  factory ActiveTripResponse.fromJson(Map<String, dynamic> json) =>
      ActiveTripResponse(
        trip: json['trip'] != null
            ? TripDto.fromJson(json['trip'] as Map<String, dynamic>)
            : null,
      );
}

/// Trip data transfer object
class TripDto {
  final String id;
  final String depotId;
  final String agentId;
  final String fleetId;
  final String routeId;
  final String? deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final bool startedOffline;
  final TripAgentDto? agent;
  final TripFleetDto? fleet;
  final TripRouteDto? route;
  final int? ticketsCount;
  final double? totalRevenue;

  TripDto({
    required this.id,
    required this.depotId,
    required this.agentId,
    required this.fleetId,
    required this.routeId,
    this.deviceId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.startedOffline,
    this.agent,
    this.fleet,
    this.route,
    this.ticketsCount,
    this.totalRevenue,
  });

  factory TripDto.fromJson(Map<String, dynamic> json) => TripDto(
        id: json['id'] as String,
        depotId: json['depot_id'] as String,
        agentId: json['agent_id'] as String,
        fleetId: json['fleet_id'] as String,
        routeId: json['route_id'] as String,
        deviceId: json['device_id'] as String?,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        status: json['status'] as String,
        startedOffline: json['started_offline'] as bool? ?? false,
        agent: json['agent'] != null
            ? TripAgentDto.fromJson(json['agent'] as Map<String, dynamic>)
            : null,
        fleet: json['fleet'] != null
            ? TripFleetDto.fromJson(json['fleet'] as Map<String, dynamic>)
            : null,
        route: json['route'] != null
            ? TripRouteDto.fromJson(json['route'] as Map<String, dynamic>)
            : null,
        ticketsCount: json['tickets_count'] as int? ?? json['total_tickets'] as int?,
        totalRevenue: json['total_revenue'] != null
            ? (json['total_revenue'] as num).toDouble()
            : null,
      );

  /// Helper to check if trip is active
  bool get isActive => status == 'ACTIVE';

  /// Helper to check if trip is completed
  bool get isCompleted => status == 'COMPLETED';
}

/// Agent details in trip response
class TripAgentDto {
  final String id;
  final String fullName;
  final String agentCode;

  TripAgentDto({
    required this.id,
    required this.fullName,
    required this.agentCode,
  });

  factory TripAgentDto.fromJson(Map<String, dynamic> json) => TripAgentDto(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        agentCode: json['agent_code'] as String,
      );
}

/// Fleet (vehicle) details in trip response
class TripFleetDto {
  final String id;
  final String number;

  TripFleetDto({
    required this.id,
    required this.number,
  });

  factory TripFleetDto.fromJson(Map<String, dynamic> json) => TripFleetDto(
        id: json['id'] as String,
        number: json['number'] as String,
      );
}

/// Route details in trip response
class TripRouteDto {
  final String id;
  final String origin;
  final String destination;

  TripRouteDto({
    required this.id,
    required this.origin,
    required this.destination,
  });

  factory TripRouteDto.fromJson(Map<String, dynamic> json) => TripRouteDto(
        id: json['id'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
      );

  /// Helper to get route display name
  String get displayName => '$origin → $destination';
}

/// Fleet (vehicle) list item
class FleetDto {
  final String id;
  final String number;
  final String depotId;

  FleetDto({
    required this.id,
    required this.number,
    required this.depotId,
  });

  factory FleetDto.fromJson(Map<String, dynamic> json) => FleetDto(
        id: json['id'] as String,
        number: json['number'] as String,
        depotId: json['depot_id'] as String,
      );
}

/// Route list item
class RouteDto {
  final String id;
  final String origin;
  final String destination;
  final String depotId;

  RouteDto({
    required this.id,
    required this.origin,
    required this.destination,
    required this.depotId,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) => RouteDto(
        id: json['id'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        depotId: json['depot_id'] as String,
      );

  /// Helper to get route display name
  String get displayName => '$origin → $destination';
}
