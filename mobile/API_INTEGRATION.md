# API Integration Guide - Countryboy Mobile App

## 🔗 API Endpoints Reference

**Base URL**: `http://localhost:3000/api` (Development)  
**Production URL**: `https://api.countryboy.co.zw/api` (To be configured)

All authenticated requests require:
```
Authorization: Bearer {device_token}
```

---

## 📡 Device Management

### 1. Pair Device (One-time, Public)
**Endpoint**: `POST /devices/pair`  
**Authentication**: None (public endpoint)

```dart
// Request
{
  "pairing_code": "ABC234",
  "device_info": {
    "model": "Samsung Galaxy A12",
    "os_version": "Android 11",
    "app_version": "1.0.0"
  }
}

// Response (200 OK)
{
  "success": true,
  "device": {
    "id": "device-hre-003",
    "serial_number": "HRE-DEV-003",
    "token": "tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345",
    "depot_id": "depot-hre-001",
    "paired": true,
    "paired_at": "2026-03-01T10:30:00Z"
  },
  "message": "Device paired successfully"
}

// Error (400 Bad Request)
{
  "success": false,
  "error": "Invalid pairing code or code already used"
}
```

**Implementation**:
```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart

class AuthRemoteDataSource {
  final Dio dio;

  Future<DeviceModel> pairDevice({
    required String pairingCode,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final response = await dio.post(
        '/devices/pair',
        data: {
          'pairing_code': pairingCode,
          'device_info': deviceInfo,
        },
      );
      
      return DeviceModel.fromJson(response.data['device']);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'Pairing failed',
      );
    }
  }
}
```

---

## 🔐 Authentication

### 2. Agent Login (Daily, Public)
**Endpoint**: `POST /agents/login`  
**Authentication**: Bearer token (device token from pairing)

**UI Flow**: Two-step process for better UX
- **Step 1**: Collect merchant_code + agent_code → Validate
- **Step 2**: Collect PIN on separate screen with agent name displayed
- **API Call**: Send all three fields in one request after Step 2 completes

```dart
// Request
{
  "merchant_code": "HRE001",
  "agent_code": "TMO014",
  "pin": "1234"
}

// Headers
{
  "Authorization": "Bearer tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345",
  "Content-Type": "application/json"
}

// Response (200 OK)
{
  "success": true,
  "agent": {
    "id": "agent-hre-001",
    "full_name": "Tinashe Moyo",
    "agent_code": "TMO014",
    "depot_id": "depot-hre-001",
    "depot_name": "Harare - Roadport",
    "merchant_code": "HRE001",
    "status": "ACTIVE"
  },
  "session": {
    "expires_at": "2026-03-01T23:59:59Z"
  }
}

// Error (401 Unauthorized)
{
  "success": false,
  "error": "Invalid credentials"
}

// Error (403 Forbidden)
{
  "success": false,
  "error": "Agent not active. Contact your manager."
}
```

**Implementation**:
```dart
class AuthRemoteDataSource {
  Future<AgentModel> login({
    required String merchantCode,
    required String agentCode,
    required String pin,
    required String deviceToken,
  }) async {
    try {
      final response = await dio.post(
        '/agents/login',
        data: {
          'merchant_code': merchantCode,
          'agent_code': agentCode,
          'pin': pin,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $deviceToken'},
        ),
      );
      
      return AgentModel.fromJson(response.data['agent']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw InactiveAgentException(
          message: e.response?.data['error'] ?? 'Agent not active',
        );
      }
      throw ServerException(
        message: e.response?.data['error'] ?? 'Login failed',
      );
    }
  }
}
```

---

## 🚌 Trip Management

### 3. Start Trip
**Endpoint**: `POST /trips`  
**Authentication**: Bearer token

```dart
// Request
{
  "fleet_id": "fleet-hre-001",
  "route_id": "route-hre-001",
  "started_at": "2026-03-01T08:30:00Z"
}

// Response (201 Created)
{
  "success": true,
  "trip": {
    "id": "trip-007",
    "depot_id": "depot-hre-001",
    "agent_id": "agent-hre-001",
    "device_id": "device-hre-001",
    "fleet_id": "fleet-hre-001",
    "route_id": "route-hre-001",
    "started_at": "2026-03-01T08:30:00Z",
    "ended_at": null,
    "status": "ACTIVE",
    "fleet": {
      "id": "fleet-hre-001",
      "number": "HRE-101"
    },
    "route": {
      "id": "route-hre-001",
      "origin": "Harare",
      "destination": "Bulawayo"
    }
  }
}

// Error (400 Bad Request)
{
  "success": false,
  "error": "Agent already has an active trip"
}
```

### 4. Get Active Trip
**Endpoint**: `GET /trips/active`  
**Authentication**: Bearer token

```dart
// Response (200 OK) - Has active trip
{
  "success": true,
  "trip": {
    "id": "trip-007",
    "fleet": { "number": "HRE-101" },
    "route": { "origin": "Harare", "destination": "Bulawayo" },
    "started_at": "2026-03-01T08:30:00Z",
    "ticket_count": 12,
    "revenue": 180.00
  }
}

// Response (200 OK) - No active trip
{
  "success": true,
  "trip": null
}
```

### 5. End Trip
**Endpoint**: `PATCH /trips/:id/end`  
**Authentication**: Bearer token

```dart
// Request
{
  "ended_at": "2026-03-01T13:45:00Z"
}

// Response (200 OK)
{
  "success": true,
  "trip": {
    "id": "trip-007",
    "status": "COMPLETED",
    "ended_at": "2026-03-01T13:45:00Z",
    "duration_hours": 5.25,
    "ticket_count": 45,
    "total_revenue": 675.00
  }
}
```

---

## 🎫 Tickets

### 6. Issue Ticket
**Endpoint**: `POST /tickets`  
**Authentication**: Bearer token

```dart
// Request - Passenger Ticket
{
  "trip_id": "trip-007",
  "serial_number": 1042,
  "ticket_category": "PASSENGER",
  "currency": "USD",
  "amount": 15.00,
  "departure": "Harare",
  "destination": "Bulawayo",
  "issued_at": "2026-03-01T09:15:00Z"
}

// Request - Luggage Ticket (linked)
{
  "trip_id": "trip-007",
  "serial_number": 1043,
  "ticket_category": "LUGGAGE",
  "currency": "USD",
  "amount": 3.00,
  "departure": "Harare",
  "destination": "Bulawayo",
  "linked_passenger_ticket_id": "ticket-016",
  "issued_at": "2026-03-01T09:17:00Z"
}

// Response (201 Created)
{
  "success": true,
  "ticket": {
    "id": "ticket-016",
    "trip_id": "trip-007",
    "serial_number": 1042,
    "ticket_category": "PASSENGER",
    "currency": "USD",
    "amount": 15.00,
    "departure": "Harare",
    "destination": "Bulawayo",
    "issued_at": "2026-03-01T09:15:00Z",
    "created_at": "2026-03-01T09:15:02Z"
  }
}

// Error (400 Bad Request)
{
  "success": false,
  "error": "Serial number already used"
}
```

### 7. Get Tickets for Trip
**Endpoint**: `GET /tickets?trip_id={trip_id}`  
**Authentication**: Bearer token

```dart
// Response (200 OK)
{
  "success": true,
  "tickets": [
    {
      "id": "ticket-016",
      "serial_number": 1042,
      "ticket_category": "PASSENGER",
      "amount": 15.00,
      "issued_at": "2026-03-01T09:15:00Z"
    },
    // ... more tickets
  ],
  "summary": {
    "total_tickets": 12,
    "passenger_tickets": 10,
    "luggage_tickets": 2,
    "total_revenue": 186.00
  }
}
```

---

## 🔢 Serial Numbers

### 8. Get Serial Ranges
**Endpoint**: `GET /serial-ranges?device_id={device_id}&currency=USD`  
**Authentication**: Bearer token

```dart
// Response (200 OK)
{
  "success": true,
  "ranges": [
    {
      "id": "serial-hre-001",
      "currency": "USD",
      "start_number": 1000,
      "end_number": 1999,
      "next_number": 1050,
      "remaining": 950,
      "exhausted": false
    }
  ]
}

// No ranges available
{
  "success": true,
  "ranges": [],
  "message": "No serial ranges allocated. Contact admin."
}
```

---

## 🔄 Master Data (For Offline Caching)

### 9. Get Routes
**Endpoint**: `GET /routes`  
**Authentication**: Bearer token

```dart
// Response (200 OK)
{
  "success": true,
  "routes": [
    {
      "id": "route-hre-001",
      "origin": "Harare",
      "destination": "Bulawayo",
      "depot_id": "depot-hre-001"
    },
    // ... more routes
  ]
}
```

### 10. Get Fares
**Endpoint**: `GET /fares`  
**Authentication**: Bearer token

```dart
// Response (200 OK)
{
  "success": true,
  "fares": [
    {
      "id": "fare-hre-001",
      "route_id": "route-hre-001",
      "currency": "USD",
      "amount": 15.00
    },
    // ... more fares
  ]
}
```

### 11. Get Fleets
**Endpoint**: `GET /fleets`  
**Authentication**: Bearer token

```dart
// Response (200 OK)
{
  "success": true,
  "fleets": [
    {
      "id": "fleet-hre-001",
      "number": "HRE-101",
      "depot_id": "depot-hre-001"
    },
    // ... more fleets
  ]
}
```

---

## 🔄 Sync Operations

### Sync Strategy

**When to sync**:
1. On app launch (if online)
2. After successful login
3. Every 15 minutes in background (WorkManager)
4. When user pulls to refresh
5. Before ending a trip

**What to sync**:
1. **Upload**: Pending tickets, completed trips
2. **Download**: Master data (routes, fares, fleets), serial ranges

**Implementation**:
```dart
// lib/features/sync/domain/usecases/sync_all.dart

class SyncAll {
  final SyncRepository repository;

  Future<SyncResult> call() async {
    // 1. Check connectivity
    final isOnline = await repository.checkConnectivity();
    if (!isOnline) {
      return SyncResult.offline();
    }

    try {
      // 2. Upload pending tickets
      final pendingTickets = await repository.getPendingTickets();
      for (final ticket in pendingTickets) {
        await repository.uploadTicket(ticket);
        await repository.markTicketSynced(ticket.id);
      }

      // 3. Upload completed trips
      final completedTrips = await repository.getPendingTrips();
      for (final trip in completedTrips) {
        await repository.uploadTripEnd(trip);
        await repository.markTripSynced(trip.id);
      }

      // 4. Download master data
      final routes = await repository.fetchRoutes();
      await repository.saveRoutes(routes);

      final fares = await repository.fetchFares();
      await repository.saveFares(fares);

      final fleets = await repository.fetchFleets();
      await repository.saveFleets(fleets);

      // 5. Refresh serial ranges
      final ranges = await repository.fetchSerialRanges();
      await repository.saveSerialRanges(ranges);

      // 6. Update last sync timestamp
      await repository.updateLastSyncTime(DateTime.now());

      return SyncResult.success(
        uploadedTickets: pendingTickets.length,
        uploadedTrips: completedTrips.length,
      );
    } catch (e) {
      return SyncResult.failure(error: e.toString());
    }
  }
}
```

---

## ⚠️ Error Handling

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process data |
| 201 | Created | Process created resource |
| 400 | Bad Request | Show validation errors |
| 401 | Unauthorized | Re-login or re-pair device |
| 403 | Forbidden | Show "Agent not active" error |
| 404 | Not Found | Show "Resource not found" |
| 409 | Conflict | Show "Duplicate serial number" |
| 500 | Server Error | Retry with exponential backoff |
| Network Error | No connectivity | Queue for later sync |

### Error Models

```dart
// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message = 'No internet connection';
}

class CacheException implements Exception {
  final String message;
  
  CacheException({required this.message});
}

class InactiveAgentException implements Exception {
  final String message;
  
  InactiveAgentException({required this.message});
}
```

### User-Friendly Error Messages

```dart
// lib/core/utils/error_handler.dart

class ErrorHandler {
  static String getUserMessage(Exception error) {
    if (error is NetworkException) {
      return 'No internet connection. Working offline.';
    }
    
    if (error is InactiveAgentException) {
      return 'Your account is not active. Please contact your manager.';
    }
    
    if (error is ServerException) {
      if (error.statusCode == 401) {
        return 'Session expired. Please log in again.';
      }
      if (error.statusCode == 409) {
        return 'This ticket serial number has already been used.';
      }
      return error.message;
    }
    
    return 'Something went wrong. Please try again.';
  }
}
```

---

## 📱 Device Info Collection

```dart
// lib/core/utils/device_info.dart

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoHelper {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'model': '${androidInfo.brand} ${androidInfo.model}',
        'os_version': 'Android ${androidInfo.version.release}',
        'app_version': packageInfo.version,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'model': '${iosInfo.name} ${iosInfo.model}',
        'os_version': 'iOS ${iosInfo.systemVersion}',
        'app_version': packageInfo.version,
      };
    }
    
    return {
      'model': 'Unknown',
      'os_version': 'Unknown',
      'app_version': packageInfo.version,
    };
  }
}
```

---

## 🧪 Testing with Mock Data

### Test Credentials (from server/TEST_CREDENTIALS.md)

```dart
// lib/core/config/test_config.dart

class TestConfig {
  // Pairing Codes
  static const pairingCodeHarare = 'ABC234';
  static const pairingCodeBulawayo = 'XYZ789';
  
  // Agent Login
  static const merchantCodeHarare = 'HRE001';
  static const merchantCodeBulawayo = 'BYO001';
  static const merchantCodeMutare = 'MUT001';
  
  static const agentCodeTinashe = 'TMO014';
  static const agentCodeFarai = 'FNC015';
  static const agentCodeNkululeko = 'NDU021';
  
  static const defaultPin = '1234';
  
  // Device Tokens (already paired)
  static const deviceTokenHre001 = 'tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890';
  static const deviceTokenByo001 = 'tok-c3d4e5f6-a7b8-4901-c3d4-e5f6a7b89012';
}
```

---

## 🔐 Secure Storage

```dart
// lib/core/storage/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Keys
  static const _deviceTokenKey = 'device_token';
  static const _deviceIdKey = 'device_id';
  static const _agentIdKey = 'agent_id';
  
  // Device Token
  Future<void> saveDeviceToken(String token) async {
    await _storage.write(key: _deviceTokenKey, value: token);
  }
  
  Future<String?> getDeviceToken() async {
    return await _storage.read(key: _deviceTokenKey);
  }
  
  Future<bool> hasDeviceToken() async {
    final token = await getDeviceToken();
    return token != null;
  }
  
  // Clear all (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

---

## 📊 API Call Examples

### Complete Flow Example

```dart
// 1. Pair Device (First time)
final device = await authRemoteDataSource.pairDevice(
  pairingCode: 'ABC234',
  deviceInfo: await DeviceInfoHelper.getDeviceInfo(),
);
await secureStorage.saveDeviceToken(device.token);

// 2. Daily Login
final agent = await authRemoteDataSource.login(
  merchantCode: 'HRE001',
  agentCode: 'TMO014',
  pin: '1234',
  deviceToken: await secureStorage.getDeviceToken(),
);
await sharedPrefs.saveAgent(agent);

// 3. Start Trip
final trip = await tripRemoteDataSource.startTrip(
  fleetId: 'fleet-hre-001',
  routeId: 'route-hre-001',
  startedAt: DateTime.now(),
  deviceToken: await secureStorage.getDeviceToken(),
);

// 4. Issue Ticket
final ticket = await ticketRemoteDataSource.issueTicket(
  tripId: trip.id,
  serialNumber: 1042,
  category: 'PASSENGER',
  currency: 'USD',
  amount: 15.00,
  departure: 'Harare',
  destination: 'Bulawayo',
  issuedAt: DateTime.now(),
  deviceToken: await secureStorage.getDeviceToken(),
);

// 5. End Trip
await tripRemoteDataSource.endTrip(
  tripId: trip.id,
  endedAt: DateTime.now(),
  deviceToken: await secureStorage.getDeviceToken(),
);
```

---

## 🌐 API Client Setup

```dart
// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  late final Dio dio;
  
  ApiClient({required String baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors
    dio.interceptors.addAll([
      AuthInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }
}

// Interceptor to add auth token
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final secureStorage = SecureStorageService();
    final token = await secureStorage.getDeviceToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 - trigger re-login
    if (err.response?.statusCode == 401) {
      // Emit event to logout and show login screen
      // eventBus.fire(UnauthorizedEvent());
    }
    
    handler.next(err);
  }
}
```

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026  
**See Also**: [Implementation Plan](./IMPLEMENTATION_PLAN.md)
