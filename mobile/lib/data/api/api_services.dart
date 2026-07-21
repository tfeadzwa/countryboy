import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../domain/models/models.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<LoginResult> login({
    required String merchantCode,
    required String agentCode,
    required String pin,
    String? deviceToken,
    String? deviceId,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (deviceToken != null && deviceToken.isNotEmpty) {
        headers['x-device-token'] = deviceToken;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/agents/login',
        data: {
          'merchant_code': merchantCode.toUpperCase(),
          'agent_code': agentCode.toUpperCase(),
          'pin': pin,
          'app_version': Env.appVersion,
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
        options: Options(headers: headers),
      );
      final data = response.data!;
      return LoginResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        agent: AgentProfile.fromJson(data['agent'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.error is ApiError ? e.error as ApiError : ApiError.network();
    }
  }

  Future<void> logout({String? deviceToken}) async {
    try {
      final headers = <String, dynamic>{};
      if (deviceToken != null && deviceToken.isNotEmpty) {
        headers['x-device-token'] = deviceToken;
      }
      await _dio.post('/agents/logout', options: Options(headers: headers));
    } on DioException {
      // Stateless JWT — ignore network errors on logout.
    }
  }
}

final deviceApiProvider = Provider<DeviceApi>((ref) {
  return DeviceApi(ref.watch(dioProvider));
});

class DeviceApi {
  DeviceApi(this._dio);
  final Dio _dio;

  Future<PairDeviceResult> pair({
    required String pairingCode,
    String? deviceName,
    String? deviceModel,
    String? appVersion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/devices/pair',
        data: {
          'pairing_code': pairingCode.toUpperCase().replaceAll('-', ''),
          if (deviceName != null) 'device_name': deviceName,
          if (deviceModel != null) 'device_model': deviceModel,
          if (appVersion != null) 'app_version': appVersion,
        },
      );
      return PairDeviceResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw e.error is ApiError ? e.error as ApiError : ApiError.network();
    }
  }
}

final referenceApiProvider = Provider<ReferenceApi>((ref) {
  return ReferenceApi(ref.watch(dioProvider));
});

class ReferenceApi {
  ReferenceApi(this._dio);
  final Dio _dio;

  Future<List<FleetModel>> getFleets() async {
    final response = await _dio.get<List<dynamic>>('/fleets');
    return (response.data ?? [])
        .map((e) => FleetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteModel>> getRoutes() async {
    final response = await _dio.get<List<dynamic>>('/routes');
    return (response.data ?? [])
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FareModel>> getFares() async {
    final response = await _dio.get<List<dynamic>>('/fares');
    return (response.data ?? [])
        .map((e) => FareModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final tripApiProvider = Provider<TripApi>((ref) {
  return TripApi(ref.watch(dioProvider));
});

class TripApi {
  TripApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> startTrip({
    required String fleetId,
    required String routeId,
    String? tripId,
    String? deviceId,
    bool startedOffline = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/agents/trips/start',
      data: {
        if (tripId != null) 'id': tripId,
        'fleet_id': fleetId,
        'route_id': routeId,
        if (deviceId != null) 'device_id': deviceId,
        'started_offline': startedOffline,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> endTrip(String tripId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/agents/trips/$tripId/end',
    );
    return response.data!;
  }

  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/agents/trips/active');
      return response.data?['trip'] as Map<String, dynamic>?;
    } on DioException {
      return null;
    }
  }
}

final ticketApiProvider = Provider<TicketApi>((ref) {
  return TicketApi(ref.watch(dioProvider));
});

class TicketApi {
  TicketApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> issueTicket({
    required String tripId,
    required String ticketCategory,
    required String currency,
    required double amount,
    String? deviceId,
    String? departure,
    String? destination,
    DateTime? issuedAt,
    String? linkedPassengerTicketId,
    String? passengerPhone,
    double? luggageAmount,
    String? luggageDescription,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tickets',
      data: {
        'trip_id': tripId,
        'ticket_category': ticketCategory,
        'currency': currency,
        'amount': amount,
        if (deviceId != null) 'device_id': deviceId,
        if (departure != null) 'departure': departure,
        if (destination != null) 'destination': destination,
        if (issuedAt != null) 'issued_at': issuedAt.toIso8601String(),
        if (linkedPassengerTicketId != null)
          'linked_passenger_ticket_id': linkedPassengerTicketId,
        if (passengerPhone != null && passengerPhone.isNotEmpty)
          'passenger_phone': passengerPhone,
        if (luggageAmount != null) 'luggage_amount': luggageAmount,
        if (luggageDescription != null && luggageDescription.isNotEmpty)
          'luggage_description': luggageDescription,
      },
    );
    return response.data!;
  }
}

final syncApiProvider = Provider<SyncApi>((ref) {
  return SyncApi(ref.watch(dioProvider));
});

class SyncApi {
  SyncApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> push({
    List<Map<String, dynamic>>? trips,
    List<Map<String, dynamic>>? tickets,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/push',
      data: {
        if (trips != null && trips.isNotEmpty) 'trips': trips,
        if (tickets != null && tickets.isNotEmpty) 'tickets': tickets,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> pull({String? since}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: since != null ? {'since': since} : null,
    );
    return response.data!;
  }
}
