# Offline Functionality - Current Status

## 📊 Implementation Overview

### ✅ What's Currently Implemented

#### 1. **Offline Login System**
**Status**: ✅ FULLY IMPLEMENTED

**How it works**:
1. User logs in online with merchant code, agent code, and PIN
2. After successful online login, a dialog asks: "Enable Offline Login?"
3. If user clicks "Yes, Enable":
   - Credentials (merchant code, agent code, PIN) are encrypted and stored locally using `flutter_secure_storage`
   - Storage location: Android Keystore / iOS Keychain (highly secure)

**Offline Login Process**:
```dart
// File: mobile/lib/domain/repositories/auth_repository.dart

1. User opens app without internet
2. Login screen detects no connectivity
3. Shows "No internet connection - Using offline mode" banner
4. User enters same credentials
5. System validates locally stored encrypted credentials
6. If valid: Generates offline token (1 hour expiry)
7. User is logged in without internet
```

**Security**:
- ✅ Offline tokens expire in 1 hour (same as online tokens)
- ✅ Credentials stored encrypted
- ✅ Cannot login offline without first enabling it while online
- ✅ PIN validation happens locally (no server call)

#### 2. **Token Refresh System**
**Status**: ✅ FULLY IMPLEMENTED

**How it works**:
```
Timeline:
0 min  → User logs in (gets 1hr access token + 7d refresh token)
5 min  → Home screen timer checks if refresh needed (NO)
10 min → Timer checks again (NO)
...
50 min → Timer detects 50 minutes elapsed → Triggers auto-refresh
        → Background API call: POST /api/auth/refresh
        → Gets new 1hr access + 7d refresh tokens
        → Updates storage, resets timer to 0
55 min → Timer checks (NO refresh needed, just reset)
60 min → Would have expired, but already refreshed at 50min
```

**Implementation Details**:
- Location: `mobile/lib/features/home/home_screen.dart`
- Timer: Checks every 5 minutes
- Trigger: When 50+ minutes elapsed since last token issued
- Buffer: 10-minute safety margin before expiry
- Silent: User doesn't see any UI changes

#### 3. **HTTP Interceptor (Auto-Recovery)**
**Status**: ✅ FULLY IMPLEMENTED

**How it works**:
```dart
// File: mobile/lib/core/network/api_interceptor.dart

User Action → API Request → 401 Unauthorized
                ↓
        TokenRefreshInterceptor catches error
                ↓
        Checks if offline session (skip refresh)
                ↓
        Has refresh token? → POST /api/auth/refresh
                ↓
        Success → Retry original request with new token
                ↓
        User doesn't notice (seamless)
```

**Edge Cases Handled**:
- ✅ Offline token expired → Clears token, redirects to login
- ✅ Refresh token expired → Clears auth, redirects to login
- ✅ Agent deactivated → Refresh fails, redirects to login
- ✅ Multiple simultaneous 401s → Only one refresh call (race condition protection)

---

### ❌ What's NOT Implemented (Critical Gaps)

#### 1. **Offline Data Sync for Fleets**
**Status**: ❌ NOT IMPLEMENTED

**Current Behavior**:
```dart
// File: mobile/lib/data/repositories/trip_repository.dart

Future<List<FleetDto>> getFleets() async {
  return await _apiService.getFleets(); // ❌ Always hits API
}
```

**What happens offline**:
```
User logged in offline → Clicks "Start Trip"
  ↓
Tries to load fleets → API call to /api/agents/fleets
  ↓
Network error (no internet) → Fleet list shows error
  ↓
User cannot select fleet → Cannot start trip ❌
```

**What SHOULD happen**:
```
User logs in online → Fleets fetched and cached in local DB
  ↓
User goes offline → App checks local DB first
  ↓
Fleets loaded from cache → User can select fleet ✅
  ↓
Trip creation queued → Synced when online ✅
```

#### 2. **Offline Data Sync for Routes**
**Status**: ❌ NOT IMPLEMENTED

**Current Behavior**:
```dart
// File: mobile/lib/data/repositories/trip_repository.dart

Future<List<RouteDto>> getRoutes() async {
  return await _apiService.getRoutes(); // ❌ Always hits API
}
```

**Same problem as fleets**: Cannot fetch routes offline.

#### 3. **Local Database Integration**
**Status**: ⚠️ PARTIALLY IMPLEMENTED

**What EXISTS**:
- ✅ Database schema defined (`mobile/lib/data/local/database.dart`)
- ✅ Tables: Devices, Agents, Routes, Trips, Tickets, SyncQueue
- ✅ CRUD operations available
- ✅ Drift (SQLite) package configured

**What's MISSING**:
- ❌ NOT connected to trip repository
- ❌ NOT caching API responses
- ❌ NOT querying local DB before API
- ❌ NOT syncing queued operations

**Database Code** (exists but unused):
```dart
// File: mobile/lib/data/local/database.dart

// These methods EXIST but are NEVER CALLED:
Future<List<Route>> getAllActiveRoutes() async {
  return (select(routes)..where((r) => r.isActive.equals(true))).get();
}

Future<void> insertRoutes(List<RoutesCompanion> routeList) async {
  await batch((batch) {
    batch.insertAll(routes, routeList);
  });
}
```

#### 4. **Sync Queue System**
**Status**: ❌ NOT IMPLEMENTED

**What's needed**:
```
User creates trip offline → Trip stored in local DB
  ↓
Added to SyncQueue table with status: PENDING
  ↓
User goes online → Background sync service starts
  ↓
Reads SyncQueue → Finds pending trip
  ↓
POST /api/agents/trips/start → Success
  ↓
Updates SyncQueue status: SYNCED
  ↓
Updates local trip with server ID
```

**Currently**: No sync queue logic exists.

#### 5. **Offline Trip Management**
**Status**: ❌ NOT IMPLEMENTED

**Cannot do offline**:
- ❌ Start trip (requires fleet/route selection)
- ❌ Issue tickets
- ❌ End trip
- ❌ View trip history

---

## 🔬 Testing Current Implementation

### Test 1: Offline Login (✅ Works)
```
Steps:
1. Login online (TMO014, HRE001, PIN: 1234)
2. Dialog appears: "Enable Offline Login?"
3. Click "Yes, Enable"
4. Logout
5. Turn on Airplane Mode
6. Open app → Login screen
7. Enter same credentials
8. See: "Logged in offline. Token valid for 1 hour."

Result: ✅ USER IS LOGGED IN
```

### Test 2: Fetch Fleets Offline (❌ Fails)
```
Steps:
1. Complete Test 1 (logged in offline)
2. Navigate to "Start Trip"
3. Screen tries to load fleets

Result: ❌ ERROR: "No internet connection" or timeout
Effect: Cannot start trip
```

### Test 3: Token Auto-Refresh Online (✅ Works)
```
Steps:
1. Login online
2. Wait 50+ minutes (or modify code to trigger at 5min for testing)
3. Home screen timer triggers refresh
4. New tokens saved
5. User doesn't notice anything

Result: ✅ SEAMLESS REFRESH
```

### Test 4: HTTP Interceptor Recovery (✅ Works)
```
Steps:
1. Login online
2. Manually expire access token (wait 1hr or delete from storage)
3. Try to fetch fleets
4. API returns 401
5. Interceptor catches error
6. Calls refresh endpoint
7. Retries original request

Result: ✅ AUTOMATIC RECOVERY (if refresh token valid)
```

---

## 🛠️ What Needs to be Implemented

### Priority 1: Offline Data Caching

**Required Changes**:

1. **Update Trip Repository** to check local DB first:
```dart
// mobile/lib/data/repositories/trip_repository.dart

Future<List<FleetDto>> getFleets() async {
  try {
    // Try online first
    final fleets = await _apiService.getFleets();
    
    // Cache in local DB
    await _localDatabase.cacheFleets(fleets);
    
    return fleets;
  } catch (e) {
    // If offline, try local cache
    final cachedFleets = await _localDatabase.getCachedFleets();
    
    if (cachedFleets.isNotEmpty) {
      return cachedFleets;
    }
    
    throw Exception('No internet and no cached data');
  }
}
```

2. **Similar pattern for Routes**:
```dart
Future<List<RouteDto>> getRoutes() async {
  // Same pattern: Try online → Cache → Fallback to cache
}
```

### Priority 2: Offline Trip Creation

**Required Changes**:

1. **Queue trip creation when offline**:
```dart
Future<StartTripResponse> startTrip(StartTripRequest request) async {
  if (isOffline) {
    // Create trip in local DB
    final localTrip = await _localDatabase.createTripLocally(request);
    
    // Add to sync queue
    await _localDatabase.addToSyncQueue(
      operation: 'CREATE_TRIP',
      data: request.toJson(),
      localId: localTrip.id,
    );
    
    return StartTripResponse.fromLocal(localTrip);
  } else {
    // Normal online creation
    return await _apiService.startTrip(request);
  }
}
```

2. **Background sync service**:
```dart
class SyncService {
  Future<void> syncPendingOperations() async {
    final pending = await _database.getPendingSyncQueue();
    
    for (final operation in pending) {
      try {
        switch (operation.type) {
          case 'CREATE_TRIP':
            await _apiService.startTrip(operation.data);
            await _database.markSynced(operation.id);
            break;
          // ... other operations
        }
      } catch (e) {
        // Mark failed, retry later
        await _database.markSyncFailed(operation.id);
      }
    }
  }
}
```

### Priority 3: Connectivity Detection

**Add throughout app**:
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

// Check before API calls
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  // Use offline mode
}
```

---

## 📋 Summary Table

| Feature | Status | Works Offline? | Notes |
|---------|--------|----------------|-------|
| **Login** | ✅ Implemented | ✅ YES | If enabled after online login |
| **Token Refresh** | ✅ Implemented | ❌ NO | Requires internet for refresh API |
| **Auto-Recovery (401)** | ✅ Implemented | ❌ NO | Interceptor needs internet |
| **Fetch Fleets** | ⚠️ Partial | ❌ NO | Hits API, no cache fallback |
| **Fetch Routes** | ⚠️ Partial | ❌ NO | Hits API, no cache fallback |
| **Start Trip** | ⚠️ Partial | ❌ NO | Requires fleet/route selection |
| **Issue Tickets** | ⚠️ Partial | ❌ NO | API only, not queued |
| **End Trip** | ⚠️ Partial | ❌ NO | API only, not queued |
| **Create Fleet** | ⚠️ Partial | ❌ NO | API only, not queued |
| **Create Route** | ⚠️ Partial | ❌ NO | API only, not queued |
| **Local Database** | ✅ Schema exists | ❌ NOT USED | Drift DB defined but not connected |
| **Sync Queue** | ✅ Table exists | ❌ NO LOGIC | No sync service implemented |

---

## 🎯 User Journey - What Actually Works

### Scenario A: User Enabled Offline Login

**Online Actions** (✅ All work):
1. ✅ Login with credentials
2. ✅ Enable offline mode
3. ✅ Start trip (fetch fleets/routes online)
4. ✅ Issue tickets
5. ✅ End trip
6. ✅ Logout

**Go Offline** → Turn on Airplane Mode

**Offline Actions**:
1. ✅ Login with same credentials (validates locally)
2. ❌ **CANNOT** start trip (no fleets/routes cached)
3. ❌ **CANNOT** issue tickets (requires active trip)
4. ❌ **CANNOT** end trip
5. ✅ Logout (local operation)

### Scenario B: User Didn't Enable Offline Login

**Go Offline**:
1. ❌ **CANNOT** login at all (no stored credentials)
2. ❌ Stuck on login screen

---

## 💡 Recommendations

### Short-term (Fix Critical Path):
1. **Implement fleet/route caching** - Store in local DB after online fetch
2. **Add cache fallback** - Check local DB if API fails
3. **Show cache age** - "Last updated 2 hours ago" to manage expectations

### Medium-term (Enable Offline Operations):
1. **Implement sync queue** - Store offline operations
2. **Background sync service** - Auto-sync when online
3. **Conflict resolution** - Handle server/local differences

### Long-term (Full Offline Support):
1. **Differential sync** - Only fetch changes since last sync
2. **Compressed payloads** - Reduce data usage
3. **Smart prefetching** - Cache data proactively

---

## 🔧 Current Configuration

**Token Lifespans**:
- Access Token: 1 hour
- Refresh Token: 7 days
- Offline Token: 1 hour (for security on shared POS devices)

**Refresh Strategy**:
- Trigger: 50 minutes after token issued
- Check: Every 5 minutes (home screen timer)
- Buffer: 10 minutes before expiry

**Storage**:
- Secure: `flutter_secure_storage` (tokens, credentials)
- Preferences: `shared_preferences` (non-sensitive settings)
- Database: Drift/SQLite (data caching - **not yet used**)

---

**Last Updated**: March 6, 2026  
**Implementation Status**: Phase 1 Complete (Auth), Phase 2 Pending (Data Sync)
