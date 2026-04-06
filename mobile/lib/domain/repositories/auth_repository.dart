import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../data/api/auth_api_service.dart';
import '../../data/dto/auth_dto.dart';
import '../../core/storage/storage_service.dart';
import '../../core/network/api_error.dart';

/// Authentication repository handling device pairing and agent login
class AuthRepository {
  final AuthApiService _apiService;
  final StorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  // ========== Device Pairing ==========

  /// Pair device with pairing code
  Future<PairDeviceResponse> pairDevice(String pairingCode) async {
    try {
      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown Device';
      String deviceModel = 'Unknown Model';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        deviceModel = iosInfo.model;
      }

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Create request
      final request = PairDeviceRequest(
        pairingCode: pairingCode,
        deviceName: deviceName,
        deviceModel: deviceModel,
        appVersion: appVersion,
      );

      // Call API
      final response = await _apiService.pairDevice(request);

      // Save device token and merchant code
      await _storageService.saveDeviceToken(response.deviceToken);
      await _storageService.saveMerchantCode(response.merchantCode);

      return response;
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to pair device: $e',
      );
    }
  }

  /// Check if device is paired
  Future<bool> isPaired() async {
    return await _storageService.isPaired();
  }

  /// Get merchant code
  String? getMerchantCode() {
    return _storageService.getMerchantCode();
  }

  // ========== Agent Authentication ==========

  /// Login agent with PIN
  Future<LoginResponse> login({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    try {
      // Create request
      final request = LoginRequest(
        merchantCode: merchantCode,
        agentCode: agentCode,
        pin: pin,
      );

      // Call API
      final response = await _apiService.login(request);

      // Save tokens and agent data
      await _storageService.saveAuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Save token issued timestamp
      await _storageService.saveTokenIssuedAt(DateTime.now());

      await _storageService.saveAgentData(
        agentId: response.agent.id,
        agentData: {
          'id': response.agent.id,
          'agent_code': response.agent.agentCode,
          'first_name': response.agent.firstName,
          'last_name': response.agent.lastName,
          'role': response.agent.role,
          'merchant_code': response.agent.merchantCode,
          'merchant_name': response.agent.merchantName,
          'depot_code': response.agent.depotCode,
          'depot_name': response.agent.depotName,
        },
      );

      return response;
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to login: $e',
      );
    }
  }

  /// Check if agent is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Get current agent data
  Future<Map<String, dynamic>?> getCurrentAgent() async {
    return await _storageService.getAgentData();
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  // ========== Token Refresh ==========

  /// Refresh access token using refresh token
  Future<void> refreshAccessToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        throw ApiError(
          type: ApiErrorType.unauthorized,
          message: 'No refresh token available',
        );
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _apiService.refreshToken(request);

      // Save new tokens
      await _storageService.saveAuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Reset token issued time
      await _storageService.saveTokenIssuedAt(DateTime.now());
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to refresh token: $e',
      );
    }
  }

  /// Check if token needs refresh and refresh automatically
  Future<bool> autoRefreshIfNeeded() async {
    if (_storageService.shouldRefreshToken()) {
      try {
        await refreshAccessToken();
        return true;
      } catch (e) {
        // Refresh failed, user needs to login again
        return false;
      }
    }
    return true; // No refresh needed
  }

  // ========== Offline Login ==========

  /// Enable offline login capability
  Future<void> enableOfflineLogin({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    await _storageService.enableOfflineLogin(
      merchantCode: merchantCode,
      agentCode: agentCode,
      pin: pin,
    );
  }

  /// Login offline (no internet required)
  Future<bool> loginOffline({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    try {
      // Validate credentials against stored
      final isValid = await _storageService.validateOfflineCredentials(
        merchantCode: merchantCode,
        agentCode: agentCode,
        pin: pin,
      );

      if (!isValid) {
        throw ApiError(
          type: ApiErrorType.unauthorized,
          message: 'Invalid offline credentials',
        );
      }

      // Generate offline token (1 hour expiry)
      await _storageService.generateOfflineToken();
      await _storageService.setIsLoggedIn(true);

      return true;
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Offline login failed: $e',
      );
    }
  }

  /// Check if offline login is available
  bool isOfflineLoginEnabled() {
    return _storageService.isOfflineEnabled();
  }

  /// Check if current session is offline
  Future<bool> isOfflineSession() async {
    final accessToken = await _storageService.getAccessToken();
    final offlineToken = await _storageService.getOfflineToken();
    
    // If we have offline token but no access token, it's offline
    return offlineToken != null && accessToken == null;
  }

  /// Validate offline token (for security - 1 hour expiry)
  bool isOfflineTokenValid() {
    return _storageService.isOfflineTokenValid();
  }

  // ========== Logout ==========

  /// Logout current agent
  Future<void> logout() async {
    try {
      // Call API to invalidate token
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      // Clear auth data locally
      await _storageService.clearAuthData();
    }
  }

  /// Unpair device (clear all data)
  Future<void> unpairDevice() async {
    await _storageService.clearAllData();
  }
}
