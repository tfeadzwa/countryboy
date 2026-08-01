import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(const FlutterSecureStorage()),
);

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenIssuedAtKey = 'token_issued_at';
  static const _deviceTokenKey = 'device_token';
  static const _deviceIdKey = 'device_id';
  static const _depotIdKey = 'depot_id';
  static const _depotNameKey = 'depot_name';
  static const _merchantCodeKey = 'merchant_code';
  static const _serialNumberKey = 'serial_number';
  static const _pairedKey = 'device_paired';
  static const _agentJsonKey = 'agent_profile';
  static const _offlineEnabledKey = 'offline_login_enabled';
  static const _offlinePinHashKey = 'offline_pin_hash';
  static const _offlineMerchantKey = 'offline_merchant_code';
  static const _offlineAgentKey = 'offline_agent_code';
  static const _offlineSessionKey = 'offline_session';
  static const _offlineSessionExpiryKey = 'offline_session_expiry';
  static const _printerMacKey = 'printer_mac';
  static const _printerNameKey = 'printer_name';
  static const _printerSerialKey = 'printer_serial';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(
      key: _tokenIssuedAtKey,
      value: DateTime.now().toIso8601String(),
    );
    await _storage.delete(key: _offlineSessionKey);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> getTokenIssuedAt() async {
    final value = await _storage.read(key: _tokenIssuedAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<bool> shouldRefreshToken() async {
    final issuedAt = await getTokenIssuedAt();
    if (issuedAt == null) return false;
    return DateTime.now().difference(issuedAt).inMinutes >= 50;
  }

  Future<void> clearAuthTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenIssuedAtKey);
  }

  Future<void> clearAllAuth() async {
    await clearAuthTokens();
    await _storage.delete(key: _agentJsonKey);
    await _storage.delete(key: _offlineSessionKey);
    await _storage.delete(key: _offlineSessionExpiryKey);
  }

  Future<void> saveDevicePairing({
    required String deviceId,
    required String deviceToken,
    required String depotId,
    required String merchantCode,
    required String serialNumber,
    String? depotName,
  }) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
    await _storage.write(key: _deviceTokenKey, value: deviceToken);
    await _storage.write(key: _depotIdKey, value: depotId);
    await _storage.write(key: _merchantCodeKey, value: merchantCode);
    await _storage.write(key: _serialNumberKey, value: serialNumber);
    await _storage.write(key: _pairedKey, value: 'true');
    if (depotName != null && depotName.isNotEmpty) {
      await _storage.write(key: _depotNameKey, value: depotName);
    }
  }

  Future<bool> isDevicePaired() async =>
      (await _storage.read(key: _pairedKey)) == 'true';

  Future<String?> getDeviceToken() => _storage.read(key: _deviceTokenKey);
  Future<String?> getDeviceId() => _storage.read(key: _deviceIdKey);
  Future<String?> getDepotId() => _storage.read(key: _depotIdKey);
  Future<String?> getDepotName() => _storage.read(key: _depotNameKey);
  Future<String?> getMerchantCode() => _storage.read(key: _merchantCodeKey);
  Future<String?> getSerialNumber() => _storage.read(key: _serialNumberKey);

  Future<void> clearDevicePairing() async {
    await _storage.delete(key: _deviceIdKey);
    await _storage.delete(key: _deviceTokenKey);
    await _storage.delete(key: _depotIdKey);
    await _storage.delete(key: _depotNameKey);
    await _storage.delete(key: _merchantCodeKey);
    await _storage.delete(key: _serialNumberKey);
    await _storage.delete(key: _pairedKey);
  }

  /// Clears offline PIN cache so an unpaired device cannot keep signing in offline.
  Future<void> clearOfflineCredentials() async {
    await _storage.delete(key: _offlineEnabledKey);
    await _storage.delete(key: _offlinePinHashKey);
    await _storage.delete(key: _offlineMerchantKey);
    await _storage.delete(key: _offlineAgentKey);
    await _storage.delete(key: _offlineSessionKey);
    await _storage.delete(key: _offlineSessionExpiryKey);
  }

  Future<void> saveAgentProfile(Map<String, dynamic> agent) async {
    await _storage.write(key: _agentJsonKey, value: jsonEncode(agent));
  }

  Future<Map<String, dynamic>?> getAgentProfile() async {
    final raw = await _storage.read(key: _agentJsonKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> hasOnlineAuth() async {
    if (await isOfflineSession()) return false;
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<bool> hasValidSession() async {
    final agent = await getAgentProfile();
    if (agent == null) return false;
    final access = await getAccessToken();
    if (access != null && access.isNotEmpty) return true;
    return isOfflineSessionValid();
  }

  Future<void> enableOfflineLogin({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    final hash = _hashPin(pin, merchantCode, agentCode);
    await _storage.write(key: _offlineEnabledKey, value: 'true');
    await _storage.write(key: _offlinePinHashKey, value: hash);
    await _storage.write(key: _offlineMerchantKey, value: merchantCode);
    await _storage.write(key: _offlineAgentKey, value: agentCode);
  }

  Future<bool> isOfflineLoginEnabled() async =>
      (await _storage.read(key: _offlineEnabledKey)) == 'true';

  Future<bool> validateOfflineCredentials({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    if (!await isOfflineLoginEnabled()) return false;
    final storedMerchant = await _storage.read(key: _offlineMerchantKey);
    final storedAgent = await _storage.read(key: _offlineAgentKey);
    final storedHash = await _storage.read(key: _offlinePinHashKey);
    if (storedMerchant == null || storedAgent == null || storedHash == null) {
      return false;
    }
    if (storedMerchant != merchantCode.toUpperCase() ||
        storedAgent != agentCode.toUpperCase()) {
      return false;
    }
    return storedHash == _hashPin(pin, merchantCode, agentCode);
  }

  Future<void> startOfflineSession() async {
    final expiry = DateTime.now().add(const Duration(hours: 1));
    await _storage.write(key: _offlineSessionKey, value: 'true');
    await _storage.write(
      key: _offlineSessionExpiryKey,
      value: expiry.toIso8601String(),
    );
  }

  Future<bool> isOfflineSession() async =>
      (await _storage.read(key: _offlineSessionKey)) == 'true';

  Future<bool> isOfflineSessionValid() async {
    if (!await isOfflineSession()) return false;
    final expiryRaw = await _storage.read(key: _offlineSessionExpiryKey);
    if (expiryRaw == null) return false;
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  Future<void> savePrinter({
    required String mac,
    required String name,
    String? serial,
  }) async {
    await _storage.write(key: _printerMacKey, value: mac);
    await _storage.write(key: _printerNameKey, value: name);
    if (serial != null && serial.trim().isNotEmpty) {
      await _storage.write(key: _printerSerialKey, value: serial.trim());
    } else {
      await _storage.delete(key: _printerSerialKey);
    }
  }

  Future<String?> getPrinterMac() => _storage.read(key: _printerMacKey);
  Future<String?> getPrinterName() => _storage.read(key: _printerNameKey);
  Future<String?> getPrinterSerial() => _storage.read(key: _printerSerialKey);

  Future<void> clearPrinter() async {
    await _storage.delete(key: _printerMacKey);
    await _storage.delete(key: _printerNameKey);
    await _storage.delete(key: _printerSerialKey);
  }

  String _hashPin(String pin, String merchantCode, String agentCode) {
    final payload = '${merchantCode.toUpperCase()}:${agentCode.toUpperCase()}:$pin';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
