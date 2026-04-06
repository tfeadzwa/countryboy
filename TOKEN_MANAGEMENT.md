# Token Management System

## Overview

This document explains the comprehensive token management system implemented for the Countryboy mobile app. The system provides automatic token refresh, offline login capability, and seamless session management with a focus on security and user experience.

## Key Requirements

1. **Security**: Short-lived tokens (1 hour) to protect shared POS devices
2. **User Experience**: Automatic token refresh without manual re-login
3. **Offline Capability**: Field agents can login without internet connectivity
4. **Session Security**: Both online and offline tokens expire after 1 hour

## Architecture

### Token Types

#### Access Token
- **Lifetime**: 1 hour
- **Purpose**: Authenticates API requests
- **Storage**: Encrypted via flutter_secure_storage
- **Refresh Trigger**: 50 minutes (10-minute buffer)

#### Refresh Token
- **Lifetime**: 7 days
- **Purpose**: Obtains new access tokens
- **Storage**: Encrypted via flutter_secure_storage
- **Usage**: Automatic refresh via HTTP interceptor

#### Offline Token
- **Lifetime**: 1 hour (same as access token for security)
- **Purpose**: Enables login without internet
- **Storage**: Encrypted via flutter_secure_storage
- **Generation**: After successful online login (user opt-in)

## Components

### 1. Backend - Token Refresh Endpoint

**Location**: `server/src/routes/auth.ts`

```typescript
POST /api/auth/refresh
Request: { refresh_token: string }
Response: {
  access_token: string,
  refresh_token: string,
  message: string
}
```

**Features**:
- Validates refresh token using JWT_REFRESH_SECRET
- Checks agent still exists and is ACTIVE
- Generates new 1h access token + 7d refresh token
- Error handling for invalid/expired tokens

### 2. Mobile Storage Layer

**Location**: `mobile/lib/core/storage/storage_service.dart`

**Token Monitoring Methods**:
- `saveTokenIssuedAt(DateTime)` - Track when token was created
- `getTokenIssuedAt()` - Retrieve token timestamp
- `shouldRefreshToken()` - Returns true if ≥50 minutes elapsed

**Offline Login Methods**:
- `enableOfflineLogin(merchantCode, agentCode, pin)` - Store encrypted credentials
- `validateOfflineCredentials(...)` - Verify credentials match
- `generateOfflineToken()` - Create 1hr offline token
- `isOfflineTokenValid()` - Check if not expired
- `clearAuthData()` - Keeps offline credentials for re-login

### 3. Mobile Repository Layer

**Location**: `mobile/lib/domain/repositories/auth_repository.dart`

**Token Refresh Logic**:
```dart
// Manual refresh
Future<void> refreshAccessToken()

// Automatic refresh if needed
Future<bool> autoRefreshIfNeeded() {
  if (_storageService.shouldRefreshToken()) {
    await refreshAccessToken();
    return true;
  }
  return true; // No refresh needed
}
```

**Offline Login Logic**:
```dart
// Enable offline mode (after successful online login)
Future<void> enableOfflineLogin({
  required String merchantCode,
  required String agentCode,
  required String pin,
})

// Login offline (no internet required)
Future<bool> loginOffline({
  required String merchantCode,
  required String agentCode,
  required String pin,
})

// Check if offline is available
bool isOfflineLoginEnabled()

// Detect offline session
Future<bool> isOfflineSession()

// Validate offline token (1hr security check)
bool isOfflineTokenValid()
```

### 4. HTTP Interceptor

**Location**: `mobile/lib/core/network/api_interceptor.dart`

**Class**: `TokenRefreshInterceptor`

**Behavior**:
1. Catches 401 Unauthorized errors
2. Checks if offline session (skip refresh for offline tokens)
3. Attempts automatic token refresh
4. Retries original request with new token
5. Clears auth data if refresh fails

**Race Condition Protection**:
- Uses `_isRefreshing` flag to prevent multiple simultaneous refreshes
- Other requests wait until refresh completes

**Offline Detection**:
```dart
// Skip refresh for offline tokens
if (offlineToken != null && accessToken == null) {
  // Clear expired offline token
  await _secureStorage.delete(key: 'offline_token');
  return handler.next(err);
}
```

### 5. Login Screen

**Location**: `mobile/lib/features/auth/presentation/screens/login_pin_screen.dart`

**Features**:

1. **Connectivity Detection**:
   - Uses `connectivity_plus` package
   - Checks on screen load
   - Shows appropriate UI based on status

2. **Offline Mode UI**:
   - When offline + credentials saved → Shows "Offline Mode" banner
   - When offline + no credentials → Shows "Internet required" message
   - When online → Shows "Online" status

3. **Enable Offline Dialog**:
   - Prompts after successful online login
   - User can opt-in to offline capability
   - Explains 1-hour offline session limit

4. **Smart Login Flow**:
```dart
if (!_isOnline && _offlineLoginAvailable) {
  await _submitPinOffline();
} else {
  await _submitPinOnline();
}
```

### 6. Home Screen - Periodic Refresh

**Location**: `mobile/lib/features/home/home_screen.dart`

**Implementation**:
```dart
// Check token refresh every 5 minutes
_refreshTimer = Timer.periodic(
  const Duration(minutes: 5),
  (_) => _checkAndRefreshToken(),
);

Future<void> _checkAndRefreshToken() async {
  final success = await authRepo.autoRefreshIfNeeded();
  
  if (!success) {
    // Token refresh failed - redirect to login
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
```

**Dispose**:
- Timer is cancelled when screen is disposed
- Prevents memory leaks

## Token Lifecycle

### Online Login Flow

1. User enters merchant code, agent code, PIN
2. App calls `POST /api/agents/login`
3. Backend returns access_token + refresh_token
4. Storage saves tokens + timestamp: `saveTokenIssuedAt(DateTime.now())`
5. Dialog asks: "Enable offline login?"
   - If Yes → Credentials encrypted and stored
   - If No → Online-only mode
6. User navigates to home screen

### Auto-Refresh Flow

**Trigger 1: Periodic Check (Every 5 minutes)**
```
Home Screen Timer
→ authRepo.autoRefreshIfNeeded()
→ Check if ≥50 minutes elapsed
→ If yes: Call /auth/refresh
→ Save new tokens + reset timestamp
```

**Trigger 2: 401 Error (HTTP Interceptor)**
```
API Request → 401 Error
→ TokenRefreshInterceptor catches error
→ Check if offline session (skip if true)
→ Call /auth/refresh
→ Retry original request with new token
→ If refresh fails: Clear auth data
```

### Offline Login Flow

1. User has no internet connectivity
2. Login screen detects offline + offline enabled
3. Shows "Offline Mode" banner
4. User enters PIN
5. App validates credentials locally
6. Generates offline token (1hr expiry)
7. User navigates to home screen
8. API calls will fail → interceptor detects offline token → clears expired token
9. User must re-login when internet returns

## Security Considerations

### Why 1-Hour Tokens?

**Context**: Agents use shared POS devices in bus depots

**Risks**:
- Device left unattended during shift
- Unauthorized access to ticketing system
- Revenue theft or data manipulation

**Solution**:
- Short-lived tokens force re-authentication
- Even if device is stolen, token expires quickly
- Offline tokens also 1 hour (consistent security model)

### Token Storage

**Method**: `flutter_secure_storage`
- Uses Android Keystore / iOS Keychain
- Encrypted at rest
- Credentials never stored in plain text

**Stored Data**:
- `access_token` - JWT access token
- `refresh_token` - JWT refresh token
- `offline_token` - Generated offline token
- `offline_credentials` - Encrypted merchantCode + agentCode + PIN
- `token_issued_at` - ISO8601 timestamp
- `offline_token_expiry` - ISO8601 timestamp

### Refresh Token Rotation

**Backend Behavior**:
- Each refresh generates NEW access + refresh tokens
- Old refresh token is invalidated
- Prevents token replay attacks

### Offline Token Security

**Validation**:
```dart
isOfflineTokenValid() {
  final expiry = getOfflineTokenExpiry();
  return DateTime.now().isBefore(expiry);
}
```

**Enforcement**:
- Generated with 1-hour expiry timestamp
- Checked on every app launch
- Auto-cleared when expired

## Timing Details

### Token Lifespan
- Access Token: **1 hour** (3600 seconds)
- Refresh Token: **7 days** (604800 seconds)
- Offline Token: **1 hour** (3600 seconds)

### Refresh Trigger Points
- **50 minutes** after token issued (3000 seconds)
- **10-minute buffer** before expiry
- Checked every **5 minutes** by home screen timer

### Why 50 Minutes?

**Calculation**:
```
Token Lifetime: 60 minutes
Refresh Trigger: 50 minutes
Safety Buffer: 10 minutes
```

**Reasoning**:
- Ensures token refreshed before expiry
- Accounts for network delays (poor rural connectivity)
- Multiple retry opportunities within buffer
- Prevents race conditions near expiry

## Error Handling

### Scenario 1: Network Error During Refresh

**Behavior**:
```dart
try {
  await refreshAccessToken();
} catch (e) {
  // Refresh failed - will retry on next interval
  return false;
}
```

**User Impact**: 
- Silent failure
- Next API call triggers retry
- If still failing after 10 minutes → token expires → 401 → login screen

### Scenario 2: Expired Refresh Token

**Backend Response**: `401 Unauthorized` (JsonWebTokenError)

**Mobile Behavior**:
```dart
catch (e) {
  // Clear all auth data
  await _secureStorage.delete(key: 'access_token');
  await _secureStorage.delete(key: 'refresh_token');
  await _secureStorage.delete(key: 'agent_id');
}
```

**User Impact**: Next API call → 401 → Auto-redirect to login

### Scenario 3: Agent Deactivated

**Backend Check**:
```typescript
const agent = await prisma.tblAgents.findUnique({
  where: { id: decoded.agentId }
});

if (!agent || agent.status !== 'ACTIVE') {
  return res.status(401).json({ error: 'Agent not active' });
}
```

**User Impact**: Refresh fails → Auth cleared → Login screen

### Scenario 4: Offline Token Expired

**Detection**:
```dart
// In interceptor on 401 error
if (offlineToken != null && !isOfflineTokenValid()) {
  await _secureStorage.delete(key: 'offline_token');
  // Let error propagate to force re-login
}
```

**User Impact**: App shows "Session expired. Please login again."

## Testing Strategy

### Unit Tests

1. **Token Expiry Logic**:
   - `shouldRefreshToken()` returns true at 50min
   - `shouldRefreshToken()` returns false at 45min
   - `isOfflineTokenValid()` checks expiry correctly

2. **Credential Validation**:
   - `validateOfflineCredentials()` matches correct PIN
   - `validateOfflineCredentials()` rejects wrong PIN
   - Encrypted storage works correctly

### Integration Tests

1. **Refresh Endpoint**:
   - Valid refresh token → new tokens
   - Expired refresh token → 401
   - Invalid token → 401
   - Inactive agent → 401

2. **Interceptor**:
   - 401 error triggers refresh
   - Successful refresh retries request
   - Failed refresh clears auth
   - Offline token skips refresh attempt

### Manual Tests

1. **Online Flow**:
   - Login → Enable offline → Wait 50min → Verify auto-refresh
   - Check home screen every 5min → Confirm timer works
   - Force 401 error → Verify interceptor catches it

2. **Offline Flow**:
   - Enable offline → Toggle airplane mode → Login offline
   - Verify 1hr expiry enforced
   - Attempt API call → Verify fails gracefully

3. **Token Expiry**:
   - Let token expire (wait 1hr) → Verify auto-redirect to login
   - Test with offline token → Verify 1hr limit

4. **Edge Cases**:
   - Logout → Verify offline credentials kept
   - Re-login → Verify can login offline again
   - Unpair device → Verify everything cleared

## Configuration

### Environment Variables

**Backend** (`server/.env`):
```bash
JWT_SECRET=your-secret-key-here
JWT_REFRESH_SECRET=your-refresh-secret-here
```

### Constants

**Backend** (`server/src/services/agentService.ts`):
```typescript
const accessToken = jwt.sign(
  { agentId, depotId, role: 'AGENT' },
  JWT_SECRET,
  { expiresIn: '1h' }  // 👈 Access token lifetime
);

const refreshToken = jwt.sign(
  { agentId, type: 'refresh' },
  JWT_REFRESH_SECRET,
  { expiresIn: '7d' }  // 👈 Refresh token lifetime
);
```

**Mobile** (`mobile/lib/core/storage/storage_service.dart`):
```dart
bool shouldRefreshToken() {
  final issuedAt = getTokenIssuedAt();
  if (issuedAt == null) return false;
  
  final elapsed = DateTime.now().difference(issuedAt).inSeconds;
  return elapsed >= 3000; // 👈 50 minutes in seconds
}
```

## Deployment Checklist

- [ ] Backend: Verify JWT secrets are set in production
- [ ] Backend: Confirm token expiry times configured correctly
- [ ] Mobile: Test on physical device (not emulator)
- [ ] Mobile: Verify offline mode works in airplane mode
- [ ] Mobile: Test token refresh during active trip
- [ ] Mobile: Confirm auto-redirect on session expiry
- [ ] Security: Verify tokens encrypted at rest
- [ ] UX: Test seamless refresh (no user interruption)
- [ ] Documentation: Update user manual with offline login instructions

## Troubleshooting

### Issue: Token not refreshing automatically

**Check**:
1. Home screen timer is running: `_refreshTimer?.isActive`
2. `shouldRefreshToken()` returns true after 50min
3. Backend `/auth/refresh` endpoint is accessible
4. No network connectivity issues

### Issue: Offline login not available

**Check**:
1. User enabled offline during online login
2. Credentials saved: `isOfflineEnabled()` returns true
3. Offline token not expired
4. Connectivity detection working

### Issue: 401 errors not triggering refresh

**Check**:
1. `TokenRefreshInterceptor` added to Dio interceptors
2. Interceptor order correct (TokenRefresh before Auth)
3. Refresh token exists in storage
4. `_isRefreshing` flag not stuck (race condition)

### Issue: Offline token expires immediately

**Check**:
1. `generateOfflineToken()` sets 1hr expiry correctly
2. Device time not incorrect (affects DateTime comparison)
3. Token expiry saved in ISO8601 format

## Future Enhancements

### Planned Features

1. **Biometric Authentication**: Use fingerprint/face for offline login
2. **Token Blacklisting**: Server-side token revocation
3. **Multiple Device Management**: Track agent's logged-in devices
4. **Offline Data Sync**: Queue API calls when offline, sync when online
5. **Refresh Retry Logic**: Exponential backoff for failed refreshes
6. **Token Health Monitoring**: Analytics on refresh success rates
7. **Session Activity Tracking**: Log last API call for security audit

### Potential Improvements

1. **Dynamic Token Lifespan**: Adjust based on security context (location, time)
2. **Step-Down Authentication**: Require re-PIN for sensitive operations
3. **Token Binding**: Tie token to device fingerprint (prevent token theft)
4. **Push Notification Re-Auth**: Alert user when token about to expire

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Implemented & Ready for Testing
