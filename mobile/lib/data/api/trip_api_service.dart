import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/trip_dto.dart';
import '../../core/config/env.dart';
import '../../core/storage/storage_service.dart';

/// Trip API Service
/// 
/// Handles HTTP requests for trip operations:
/// - Start trip (select fleet + route)
/// - End trip (calculate totals)
/// - Get active trip (check current status)
class TripApiService {
  final http.Client _client;
  final StorageService? _storage;

  TripApiService({
    http.Client? client,
    StorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage;

  /// Start a new trip
  /// 
  /// POST /api/agents/trips/start
  /// Requires: agentId from JWT token (automatic)
  /// Body: fleet_id, route_id, device_id?, started_offline?
  /// 
  /// Returns: StartTripResponse with trip details
  /// 
  /// Errors:
  /// - 401: Not authenticated or session expired
  /// - 409: Agent already has an active trip
  /// - 403: Fleet or route not found in agent's depot
  /// - 400: Missing required fields
  Future<StartTripResponse> startTrip(StartTripRequest request) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.post(
      Uri.parse('${Environment.apiBaseUrl}/agents/trips/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return StartTripResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else if (response.statusCode == 409) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'You already have an active trip');
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Fleet or route not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to start trip');
    }
  }

  /// End an active trip
  /// 
  /// POST /api/agents/trips/:id/end
  /// Requires: agentId from JWT token (automatic)
  /// Verifies: Agent owns the trip (security check)
  /// 
  /// Returns: EndTripResponse with total tickets and revenue
  /// 
  /// Errors:
  /// - 401: Not authenticated
  /// - 404: Trip not found
  /// - 403: Trip belongs to another agent
  /// - 400: Trip already completed
  Future<EndTripResponse> endTrip(String tripId) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.post(
      Uri.parse('${Environment.apiBaseUrl}/agents/trips/$tripId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return EndTripResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Trip not found');
    } else if (response.statusCode == 403) {
      throw Exception('You can only end your own trips');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Trip already completed');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to end trip');
    }
  }

  /// Get agent's current active trip
  /// 
  /// GET /api/agents/trips/active
  /// Requires: agentId from JWT token (automatic)
  /// 
  /// Returns: ActiveTripResponse with trip or null
  /// 
  /// Used to:
  /// - Check if agent can start new trip
  /// - Display active trip on home screen
  /// - Validate before issuing tickets
  Future<ActiveTripResponse> getActiveTrip() async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.get(
      Uri.parse('${Environment.apiBaseUrl}/agents/trips/active'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ActiveTripResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get active trip');
    }
  }

  /// Get all fleets for agent's depot
  /// 
  /// GET /api/fleets
  /// Uses depot scoping - agent JWT token contains depotId
  /// Used for: Fleet selection dropdown when starting trip
  Future<List<FleetDto>> getFleets() async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.get(
      Uri.parse('${Environment.apiBaseUrl}/fleets'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final fleets = jsonDecode(response.body) as List<dynamic>;
      return fleets
          .map((json) => FleetDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please login again.');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Unable to load fleet vehicles');
      } catch (e) {
        throw Exception('Unable to load fleet vehicles. Please try again.');
      }
    }
  }

  /// Get all routes for agent's depot
  /// 
  /// GET /api/routes
  /// Uses depot scoping - agent JWT token contains depotId
  /// Used for: Route selection dropdown when starting trip
  Future<List<RouteDto>> getRoutes() async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.get(
      Uri.parse('${Environment.apiBaseUrl}/routes'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final routes = jsonDecode(response.body) as List<dynamic>;
      return routes
          .map((json) => RouteDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please login again.');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Unable to load routes');
      } catch (e) {
        throw Exception('Unable to load routes. Please try again.');
      }
    }
  }

  /// Create a new fleet vehicle
  /// 
  /// POST /api/agents/fleets
  /// Allows agents to add new fleet vehicles on-the-fly
  /// 
  /// Body: number (vehicle registration number)
  /// Returns: FleetDto with created fleet details
  /// 
  /// Errors:
  /// - 401: Not authenticated
  /// - 409: Fleet number already exists in depot
  /// - 400: Missing or invalid fleet number
  Future<FleetDto> createFleet(String fleetNumber) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.post(
      Uri.parse('${Environment.apiBaseUrl}/agents/fleets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'number': fleetNumber}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FleetDto.fromJson(json);
    } else if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please login again.');
    } else if (response.statusCode == 409) {
      throw Exception('This fleet number already exists');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Unable to create fleet vehicle');
      } catch (e) {
        throw Exception('Unable to create fleet vehicle. Please try again.');
      }
    }
  }

  /// Create a new route
  /// 
  /// POST /api/agents/routes
  /// Allows agents to add new routes on-the-fly
  /// 
  /// Body: origin, destination
  /// Returns: RouteDto with created route details
  /// 
  /// Errors:
  /// - 401: Not authenticated
  /// - 409: Route already exists in depot
  /// - 400: Missing or invalid origin/destination
  Future<RouteDto> createRoute(String origin, String destination) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.post(
      Uri.parse('${Environment.apiBaseUrl}/agents/routes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RouteDto.fromJson(json);
    } else if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please login again.');
    } else if (response.statusCode == 409) {
      throw Exception('This route already exists');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Unable to create route');
      } catch (e) {
        throw Exception('Unable to create route. Please try again.');
      }
    }
  }
}

