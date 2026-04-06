import '../dto/auth_dto.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_error.dart';

/// Authentication API service using Dio
class AuthApiService {
  final DioClient _dioClient;

  AuthApiService(this._dioClient);

  /// Pair device with pairing code
  Future<PairDeviceResponse> pairDevice(PairDeviceRequest request) async {
    try {
      final response = await _dioClient.post(
        '/devices/pair',
        data: request.toJson(),
      );

      return PairDeviceResponse.fromJson(response.data);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to pair device: $e',
      );
    }
  }

  /// Login agent with PIN
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        '/agents/login',
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to login: $e',
      );
    }
  }

  /// Refresh access token
  Future<RefreshTokenResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _dioClient.post(
        '/auth/refresh',
        data: request.toJson(),
      );

      return RefreshTokenResponse.fromJson(response.data);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to refresh token: $e',
      );
    }
  }

  /// Logout agent
  Future<void> logout() async {
    try {
      await _dioClient.post('/agents/logout');
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to logout: $e',
      );
    }
  }
}
