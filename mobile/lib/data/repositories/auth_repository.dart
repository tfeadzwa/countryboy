import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/models/models.dart';
import '../api/api_services.dart';

/// Shown when the paired device belongs to a different depot than the signing-in agent.
class DeviceDepotMismatch {
  const DeviceDepotMismatch({
    required this.deviceDepotName,
    required this.agentDepotName,
    required this.deviceMerchantCode,
    required this.loginMerchantCode,
  });

  final String deviceDepotName;
  final String agentDepotName;
  final String deviceMerchantCode;
  final String loginMerchantCode;

  String get message =>
      'This device is paired to $deviceDepotName ($deviceMerchantCode), '
      'but you signed in as an agent for $agentDepotName ($loginMerchantCode). '
      'Re-pair this device with a code from $agentDepotName to sync tickets.';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(secureStorageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SecureStorageService storage,
    required ConnectivityService connectivity,
  })  : _api = api,
        _storage = storage,
        _connectivity = connectivity;

  final AuthApi _api;
  final SecureStorageService _storage;
  final ConnectivityService _connectivity;

  Future<bool> isDevicePaired() => _storage.isDevicePaired();

  Future<bool> hasSession() => _storage.hasValidSession();

  Future<AgentProfile?> getCurrentAgent() async {
    final json = await _storage.getAgentProfile();
    if (json == null) return null;
    try {
      return AgentProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isOfflineSession() => _storage.isOfflineSession();

  Future<LoginResult> loginOnline({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    final reachable = await _connectivity.checkReachability();
    if (!reachable) {
      throw ApiError.network();
    }

    final result = await _api.login(
      merchantCode: merchantCode,
      agentCode: agentCode,
      pin: pin,
      deviceToken: await _storage.getDeviceToken(),
      deviceId: await _storage.getDeviceId(),
    );

    await _storage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _storage.saveAgentProfile(result.agent.toJson());
    return result;
  }

  Future<LoginResult> login({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    final reachable = await _connectivity.checkReachability();
    if (reachable) {
      return loginOnline(
        merchantCode: merchantCode,
        agentCode: agentCode,
        pin: pin,
      );
    }

    final valid = await _storage.validateOfflineCredentials(
      merchantCode: merchantCode,
      agentCode: agentCode,
      pin: pin,
    );
    if (!valid) {
      throw ApiError(
        message:
            'Cannot sign in offline. Connect to the internet for your first login, or check your credentials.',
      );
    }

    await _storage.startOfflineSession();
    final agentJson = await _storage.getAgentProfile();
    if (agentJson == null) {
      throw ApiError(message: 'No saved session found. Please login online first.');
    }

    return LoginResult(
      accessToken: '',
      refreshToken: '',
      agent: AgentProfile.fromJson(agentJson),
    );
  }

  Future<void> enableOfflineAccess({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    await _storage.enableOfflineLogin(
      merchantCode: merchantCode,
      agentCode: agentCode,
      pin: pin,
    );
  }

  Future<bool> isOfflineLoginEnabled() => _storage.isOfflineLoginEnabled();

  /// Returns mismatch details when the paired device depot differs from the agent's depot.
  Future<DeviceDepotMismatch?> getDeviceDepotMismatch({
    required String loginMerchantCode,
    required AgentProfile agent,
  }) async {
    if (!await _storage.isDevicePaired()) return null;

    final deviceDepotId = await _storage.getDepotId();
    final deviceMerchant = await _storage.getMerchantCode();
    final deviceDepotName =
        await _storage.getDepotName() ?? deviceMerchant ?? 'another depot';

    final loginMerchant = loginMerchantCode.toUpperCase();
    final pairedMerchant = deviceMerchant?.toUpperCase();

    final idMismatch = agent.depotId != null &&
        deviceDepotId != null &&
        agent.depotId != deviceDepotId;
    final merchantMismatch =
        pairedMerchant != null && pairedMerchant != loginMerchant;

    if (!idMismatch && !merchantMismatch) return null;

    return DeviceDepotMismatch(
      deviceDepotName: deviceDepotName,
      agentDepotName: agent.depotName.isNotEmpty
          ? agent.depotName
          : agent.merchantName,
      deviceMerchantCode: pairedMerchant ?? '—',
      loginMerchantCode: loginMerchant,
    );
  }

  Future<void> logout() async {
    try {
      if (!await _storage.isOfflineSession()) {
        await _api.logout(deviceToken: await _storage.getDeviceToken());
      }
    } finally {
      await _storage.clearAllAuth();
    }
  }

  Future<void> autoRefreshIfNeeded() async {
    if (await _storage.isOfflineSession()) return;
    if (!await _storage.shouldRefreshToken()) return;
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return;
    // Interceptor handles refresh on 401; proactive refresh can be added later.
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    api: ref.watch(deviceApiProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

class DeviceRepository {
  DeviceRepository({
    required DeviceApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  final DeviceApi _api;
  final SecureStorageService _storage;

  Future<PairDeviceResult> pairDevice(String pairingCode) async {
    final result = await _api.pair(pairingCode: pairingCode);
    await _storage.saveDevicePairing(
      deviceId: result.deviceId,
      deviceToken: result.deviceToken,
      depotId: result.depotId,
      merchantCode: result.merchantCode,
      serialNumber: result.serialNumber,
      depotName: result.depotName,
    );
    return result;
  }

  Future<String?> getStoredMerchantCode() => _storage.getMerchantCode();
}
