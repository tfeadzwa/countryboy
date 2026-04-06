import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Secure storage service for sensitive data and app preferences
class StorageService {
  static const _keyDeviceToken = 'device_token';
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyAgentId = 'agent_id';
  static const _keyAgentData = 'agent_data';
  static const _keyMerchantCode = 'merchant_code';
  static const _keyIsPaired = 'is_paired';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyLastSyncTime = 'last_sync_time';
  static const _keyOfflineEnabled = 'offline_enabled';
  static const _keyOfflineCredentials = 'offline_credentials';
  static const _keyOfflineToken = 'offline_token';
  static const _keyOfflineTokenExpiry = 'offline_token_expiry';
  static const _keyTokenIssuedAt = 'token_issued_at';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  StorageService(this._secureStorage, this._prefs);

  /// Initialize storage service
  static Future<StorageService> init() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    return StorageService(secureStorage, prefs);
  }

  // ========== Device Pairing ==========

  /// Save device token after pairing
  Future<void> saveDeviceToken(String token) async {
    await _secureStorage.write(key: _keyDeviceToken, value: token);
    await setIsPaired(true);
  }

  /// Get device token
  Future<String?> getDeviceToken() async {
    return await _secureStorage.read(key: _keyDeviceToken);
  }

  /// Check if device is paired
  Future<bool> isPaired() async {
    return _prefs.getBool(_keyIsPaired) ?? false;
  }

  /// Set device pairing status
  Future<void> setIsPaired(bool value) async {
    await _prefs.setBool(_keyIsPaired, value);
  }

  /// Save merchant code after pairing
  Future<void> saveMerchantCode(String merchantCode) async {
    await _prefs.setString(_keyMerchantCode, merchantCode);
  }

  /// Get merchant code
  String? getMerchantCode() {
    return _prefs.getString(_keyMerchantCode);
  }

  // ========== Authentication ==========

  /// Save authentication tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _keyAccessToken, value: accessToken),
      _secureStorage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  /// Save agent data after login
  Future<void> saveAgentData({
    required String agentId,
    required Map<String, dynamic> agentData,
  }) async {
    await _secureStorage.write(key: _keyAgentId, value: agentId);
    await _secureStorage.write(
      key: _keyAgentData,
      value: jsonEncode(agentData),
    );
    await setIsLoggedIn(true);
  }

  /// Get agent ID
  Future<String?> getAgentId() async {
    return await _secureStorage.read(key: _keyAgentId);
  }

  /// Get agent data
  Future<Map<String, dynamic>?> getAgentData() async {
    final dataStr = await _secureStorage.read(key: _keyAgentData);
    if (dataStr == null) return null;
    try {
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Set login status
  Future<void> setIsLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  /// Save token issued timestamp (for auto-refresh monitoring)
  Future<void> saveTokenIssuedAt(DateTime time) async {
    await _prefs.setString(_keyTokenIssuedAt, time.toIso8601String());
  }

  /// Get token issued timestamp
  DateTime? getTokenIssuedAt() {
    final timeStr = _prefs.getString(_keyTokenIssuedAt);
    return timeStr != null ? DateTime.tryParse(timeStr) : null;
  }

  /// Check if token needs refresh (50 minutes = 3000 seconds)
  bool shouldRefreshToken() {
    final issuedAt = getTokenIssuedAt();
    if (issuedAt == null) return false;
    
    final elapsed = DateTime.now().difference(issuedAt);
    // Refresh if 50 minutes have passed (10 min buffer before 1 hour expiry)
    return elapsed.inSeconds >= 3000;
  }

  // ========== Offline Login ==========

  /// Enable offline login (saves encrypted credentials locally)
  Future<void> enableOfflineLogin({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    // Normalize inputs - trim whitespace and uppercase
    final normalizedMerchant = merchantCode.trim().toUpperCase();
    final normalizedAgent = agentCode.trim().toUpperCase();
    final normalizedPin = pin.trim();
    
    // Store encrypted credentials
    final credentials = jsonEncode({
      'merchant_code': normalizedMerchant,
      'agent_code': normalizedAgent,
      'pin_hash': normalizedPin, // In production, hash this client-side too
    });
    
    print('💾 [STORAGE] Saving offline credentials:');
    print('   Merchant: "$normalizedMerchant" (original: "$merchantCode", length: ${normalizedMerchant.length})');
    print('   Agent: "$normalizedAgent" (original: "$agentCode", length: ${normalizedAgent.length})');
    print('   PIN: "$normalizedPin" (original: "$pin", length: ${normalizedPin.length})');
    print('   JSON: $credentials');
    
    await _secureStorage.write(
      key: _keyOfflineCredentials,
      value: credentials,
    );
    await _prefs.setBool(_keyOfflineEnabled, true);
    
    // Verify it was saved
    final saved = await _secureStorage.read(key: _keyOfflineCredentials);
    print('✅ [STORAGE] Verified saved: $saved');
  }

  /// Check if offline login is enabled
  bool isOfflineEnabled() {
    return _prefs.getBool(_keyOfflineEnabled) ?? false;
  }

  /// Get stored offline credentials
  Future<Map<String, dynamic>?> getOfflineCredentials() async {
    final credStr = await _secureStorage.read(key: _keyOfflineCredentials);
    if (credStr == null) return null;
    try {
      return jsonDecode(credStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Validate offline credentials
  Future<bool> validateOfflineCredentials({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    // Normalize inputs - trim whitespace and uppercase
    final normalizedMerchant = merchantCode.trim().toUpperCase();
    final normalizedAgent = agentCode.trim().toUpperCase();
    final normalizedPin = pin.trim();
    
    print('🔍 [STORAGE] Validating offline credentials:');
    print('   Input Merchant: "$normalizedMerchant" (original: "$merchantCode", length: ${normalizedMerchant.length})');
    print('   Input Agent: "$normalizedAgent" (original: "$agentCode", length: ${normalizedAgent.length})');
    print('   Input PIN: "$normalizedPin" (original: "$pin", length: ${normalizedPin.length})');
    
    final stored = await getOfflineCredentials();
    
    if (stored == null) {
      print('❌ [STORAGE] No stored credentials found!');
      return false;
    }
    
    final storedMerchant = stored['merchant_code']?.toString() ?? '';
    final storedAgent = stored['agent_code']?.toString() ?? '';
    final storedPin = stored['pin_hash']?.toString() ?? '';
    
    print('   Stored Merchant: "$storedMerchant" (length: ${storedMerchant.length})');
    print('   Stored Agent: "$storedAgent" (length: ${storedAgent.length})');
    print('   Stored PIN: "$storedPin" (length: ${storedPin.length})');
    
    final merchantMatch = storedMerchant == normalizedMerchant;
    final agentMatch = storedAgent == normalizedAgent;
    final pinMatch = storedPin == normalizedPin;
    
    print('   Merchant match: $merchantMatch');
    print('   Agent match: $agentMatch');
    print('   PIN match: $pinMatch');
    
    final result = merchantMatch && agentMatch && pinMatch;
    print(result ? '✅ [STORAGE] Credentials valid!' : '❌ [STORAGE] Credentials invalid!');
    
    return result;
  }

  /// Generate offline access token (valid for 1 hour)
  Future<void> generateOfflineToken() async {
    final agentId = await getAgentId();
    if (agentId == null) return;
    
    final now = DateTime.now();
    final expiry = now.add(Duration(hours: 1));
    
    // Simple offline token (not JWT, just a marker)
    final offlineToken = 'offline_${agentId}_${now.millisecondsSinceEpoch}';
    
    await _secureStorage.write(key: _keyOfflineToken, value: offlineToken);
    await _prefs.setString(_keyOfflineTokenExpiry, expiry.toIso8601String());
    await saveTokenIssuedAt(now);
  }

  /// Get offline token
  Future<String?> getOfflineToken() async {
    return await _secureStorage.read(key: _keyOfflineToken);
  }

  /// Check if offline token is valid (not expired)
  bool isOfflineTokenValid() {
    final expiryStr = _prefs.getString(_keyOfflineTokenExpiry);
    if (expiryStr == null) return false;
    
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return false;
    
    return DateTime.now().isBefore(expiry);
  }

  /// Disable offline login
  Future<void> disableOfflineLogin() async {
    await _secureStorage.delete(key: _keyOfflineCredentials);
    await _secureStorage.delete(key: _keyOfflineToken);
    await _prefs.remove(_keyOfflineEnabled);
    await _prefs.remove(_keyOfflineTokenExpiry);
  }

  // ========== Background Sync ==========

  /// Save last sync time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timeStr = _prefs.getString(_keyLastSyncTime);
    return timeStr != null ? DateTime.tryParse(timeStr) : null;
  }

  // ========== Logout & Clear ==========

  /// Clear authentication data (logout)
  Future<void> clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(key: _keyAccessToken),
      _secureStorage.delete(key: _keyRefreshToken),
      _secureStorage.delete(key: _keyAgentId),
      _secureStorage.delete(key: _keyAgentData),
      _secureStorage.delete(key: _keyOfflineToken),
    ]);
    await _prefs.remove(_keyTokenIssuedAt);
    await _prefs.remove(_keyOfflineTokenExpiry);
    await setIsLoggedIn(false);
    // Note: Keeps offline credentials so user can login offline again
  }

  /// Clear all data (including device pairing)
  Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  /// Clear only session data but keep device token
  Future<void> clearSessionOnly() async {
    await clearAuthData();
    // Keep device token and merchant code
  }
}
