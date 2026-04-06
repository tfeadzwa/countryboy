import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/ticket_dto.dart';
import '../../core/config/env.dart';
import '../../core/storage/storage_service.dart';

/// Ticket API Service
/// 
/// Handles HTTP requests for ticket operations:
/// - Issue single ticket (PASSENGER, PASSENGER_WITH_LUGGAGE, or LUGGAGE)
/// - Search tickets
class TicketApiService {
  final http.Client _client;
  final StorageService? _storage;

  TicketApiService({
    http.Client? client,
    StorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage;

  /// Issue a single ticket
  /// 
  /// POST /api/tickets
  /// Requires: JWT token with depot context
  /// Body: trip_id, ticket_category, currency, amount, departure?, destination?, linked_passenger_ticket_id?
  /// 
  /// Returns: IssueTicketResponse with ticket details
  /// 
  /// Errors:
  /// - 401: Not authenticated or session expired
  /// - 404: Trip not found
  /// - 403: Trip not in agent's depot or trip already completed
  /// - 400: Missing required fields or validation errors
  Future<IssueTicketResponse> issueTicket(IssueTicketRequest request) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _client.post(
      Uri.parse('${Environment.apiBaseUrl}/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return IssueTicketResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else if (response.statusCode == 404) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Trip not found');
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Cannot issue ticket for this trip');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to issue ticket');
    }
  }

  /// Search for tickets
  /// 
  /// GET /api/tickets/search?serial_number=123&trip_id=xxx
  /// Requires: JWT token
  /// Query: serial_number?, ticket_id?, trip_id?
  /// 
  /// Returns: List of TicketDto matching criteria
  Future<List<TicketDto>> searchTickets({
    int? serialNumber,
    String? ticketId,
    String? tripId,
  }) async {
    final token = await _storage?.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = <String, String>{};
    if (serialNumber != null) {
      queryParams['serial_number'] = serialNumber.toString();
    }
    if (ticketId != null) queryParams['ticket_id'] = ticketId;
    if (tripId != null) queryParams['trip_id'] = tripId;

    final uri = Uri.parse('${Environment.apiBaseUrl}/tickets/search')
        .replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => TicketDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired, please login again');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to search tickets');
    }
  }
}
