# Agent Login Flow Documentation

This document provides a detailed walkthrough of the agent authentication flow, showing how credentials (merchant code, agent code, and PIN) are processed from the mobile app through to the backend API.

## 📋 Table of Contents
- [Flow Overview](#flow-overview)
- [Step-by-Step Breakdown](#step-by-step-breakdown)
- [Mobile App Code](#mobile-app-code)
- [Backend API Code](#backend-api-code)
- [Database Queries](#database-queries)
- [Security Considerations](#security-considerations)
- [Error Handling](#error-handling)
- [Testing Guide](#testing-guide)

---

## 🔄 Flow Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     AGENT LOGIN FLOW                         │
└──────────────────────────────────────────────────────────────┘

📱 MOBILE APP                          🖥️  BACKEND SERVER
──────────────                         ─────────────────

1. LoginCodesScreen
   └─> User enters HRE001 (merchant)
   └─> User enters TMO014 (agent)
   └─> Click Continue
        │
        ├─> Navigate to PIN screen
        │
2. LoginPinScreen
   └─> User enters 1234 (PIN)
        │
        ├─> Call authRepository.login()
        │
3. AuthRepository
   └─> Create LoginRequest DTO
        │
        ├─> Call authApiService.login()
        │
4. AuthApiService
   └─> POST /api/agents/login          ──────>  5. Express Router
       Body: {                                      └─> Route: POST /api/agents/login
         merchant_code: HRE001                           │
         agent_code: TMO014                              ├─> agentController.login()
         pin: 1234                                       │
       }                                            6. AgentController
                                                       └─> Validate request body
                                                            │
                                                            ├─> Call agentService.loginAgent()
                                                            │
                                                       7. AgentService
                                                          ├─> Query DB: Find depot by HRE001
                                                          │    └─> depot-hre-001 found
                                                          │
                                                          ├─> Query DB: Find agent TMO014 in depot
                                                          │    └─> agent-hre-001 found
                                                          │
                                                          ├─> Bcrypt compare: PIN '1234'
                                                          │    └─> ✅ Valid
                                                          │
                                                          ├─> Generate JWT access_token (1h)
                                                          ├─> Generate JWT refresh_token (7d)
                                                          │
                                                          └─> Return agent data + tokens
8. HTTP Response: {              <──────────
     access_token: "eyJ...",
     refresh_token: "eyJ...",
     agent: { id, name, depot, ... },
     message: "Login successful"
   }
        │
9. AuthRepository
   ├─> Save access_token (secure storage)
   ├─> Save refresh_token (secure storage)
   ├─> Save agent data (SharedPreferences)
   │
10. LoginPinScreen
    └─> Show success message
    └─> Navigate to /home
         │
11. HomeScreen
    └─> Display "Welcome, Tinashe Moyo!"
    └─> Display depot name
    └─> Enable ticket issuance features
```

---

## 📝 Step-by-Step Breakdown

### Step 1: User Enters Merchant and Agent Codes

**Screen:** `LoginCodesScreen`  
**File:** `mobile/lib/features/auth/presentation/screens/login_codes_screen.dart`

**User Input:**
- Merchant Code: `HRE001` (6 characters, uppercase)
- Agent Code: `TMO014` (6 characters, uppercase)

**Validation:**
```dart
// Merchant code validation
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter merchant code';
  }
  if (value.length != 6) {
    return 'Merchant code must be 6 characters';
  }
  return null;
}

// Agent code validation
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter agent code';
  }
  if (value.length != 6) {
    return 'Agent code must be 6 characters';
  }
  return null;
}
```

**Action:**
```dart
void _continueToPin() {
  if (!_formKey.currentState!.validate()) return;

  // Navigate to PIN screen with codes
  Navigator.of(context).pushNamed(
    '/login/pin',
    arguments: {
      'merchantCode': _merchantCodeController.text,  // HRE001
      'agentCode': _agentCodeController.text,        // TMO014
    },
  );
}
```

---

### Step 2: User Enters PIN

**Screen:** `LoginPinScreen`  
**File:** `mobile/lib/features/auth/presentation/screens/login_pin_screen.dart`

**User Input:**
- PIN: `1234` (4-6 digits, entered via numeric keypad)

**PIN Entry Logic:**
```dart
String _pin = '';
final int _pinLength = 4; // Minimum length

void _onNumberPressed(int number) {
  if (_pin.length >= 6) return; // Max 6 digits
  
  setState(() {
    _pin += number.toString();
  });

  // Auto-submit when PIN length reached
  if (_pin.length >= _pinLength) {
    _submitPin();
  }
}

void _onDeletePressed() {
  if (_pin.isEmpty) return;
  
  setState(() {
    _pin = _pin.substring(0, _pin.length - 1);
  });
}
```

**Submit PIN:**
```dart
Future<void> _submitPin() async {
  if (_pin.length < _pinLength) return;

  setState(() => _isLoading = true);

  try {
    // Call authentication repository
    final authRepo = ref.read(authRepositoryProvider);
    final response = await authRepo.login(
      merchantCode: widget.merchantCode,  // HRE001
      agentCode: widget.agentCode,        // TMO014
      pin: _pin,                          // 1234
    );
    
    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${response.agent.firstName}!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    }
  } on ApiError catch (error) {
    if (mounted) {
      // Clear PIN on error
      setState(() {
        _pin = '';
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
```

---

### Step 3: Auth Repository Processes Login

**File:** `mobile/lib/domain/repositories/auth_repository.dart`

**Method:** `login()`

```dart
/// Login agent with PIN
/// Validates credentials with backend and saves session data locally
Future<LoginResponse> login({
  required String merchantCode,  // HRE001
  required String agentCode,     // TMO014
  required String pin,           // 1234
}) async {
  try {
    // 1. Create request DTO
    final request = LoginRequest(
      merchantCode: merchantCode,
      agentCode: agentCode,
      pin: pin,
    );

    // 2. Call API service
    final response = await _apiService.login(request);

    // 3. Save authentication tokens securely
    await _storageService.saveAuthTokens(
      accessToken: response.accessToken,   // JWT for API requests
      refreshToken: response.refreshToken,  // JWT for token renewal
    );

    // 4. Save agent data for offline access
    await _storageService.saveAgentData(
      agentId: response.agent.id,  // UUID String
      agentData: {
        'id': response.agent.id,  // UUID String
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
```

**Storage Operations:**

```dart
// Secure storage (flutter_secure_storage)
// Used for sensitive tokens AND agent ID
await _secureStorage.write(
  key: 'access_token',
  value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
);
await _secureStorage.write(
  key: 'refresh_token',
  value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
);
await _secureStorage.write(
  key: 'agent_id',
  value: 'agent-hre-001'  // UUID String
);
await _secureStorage.write(
  key: 'agent_data',
  value: jsonEncode(agentData)  // Full agent info
);
```

---

### Step 4: API Service Makes HTTP Request

**File:** `mobile/lib/data/api/auth_api_service.dart`

**Method:** `login()`

```dart
/// Login agent with PIN
/// Makes POST request to /api/agents/login
Future<LoginResponse> login(LoginRequest request) async {
  try {
    final response = await _dioClient.post(
      '/agents/login',  // Endpoint
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
```

**Request DTO (Data Transfer Object):**

**File:** `mobile/lib/data/dto/auth_dto.dart`

```dart
/// Agent login request
class LoginRequest {
  final String merchantCode;
  final String agentCode;
  final String pin;

  LoginRequest({
    required this.merchantCode,
    required this.agentCode,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        'merchant_code': merchantCode,
        'agent_code': agentCode,
        'pin': pin,
      };
}
```

**Actual HTTP Request:**

```http
POST http://192.168.1.240:3000/api/agents/login
Content-Type: application/json
Authorization: Bearer <device_token>

{
  "merchant_code": "HRE001",
  "agent_code": "TMO014",
  "pin": "1234"
}
```

---

### Step 5: Express Router Receives Request

**File:** `server/src/routes/agent.ts`

```typescript
import { Router } from 'express';
import * as agentController from '../controllers/agentController';

const router = Router();

// Public endpoint for agent login
// No authentication required (device token validation happens in controller)
router.post('/login', agentController.login);

export default router;
```

**Route Registration:**

**File:** `server/src/index.ts`

```typescript
import agentRoutes from './routes/agent';

// Mount agent routes at /api/agents
app.use('/api/agents', agentRoutes);

// This makes the login endpoint: POST /api/agents/login
```

---

### Step 6: Controller Validates Request

**File:** `server/src/controllers/agentController.ts`

**Method:** `login()`

```typescript
import { Request, Response } from 'express';
import * as agentService from '../services/agentService';

/**
 * Agent login for mobile app
 * Validates merchant_code + agent_code + PIN
 * 
 * @route POST /api/agents/login
 * @access Public
 */
export const login = async (req: Request, res: Response) => {
  try {
    // Extract credentials from request body
    const { merchant_code, username, agent_code, pin } = req.body;

    // Validate required fields
    if (!merchant_code || !pin) {
      return res.status(400).json({ 
        error: 'merchant_code and pin are required' 
      });
    }

    // Require either username or agent_code
    if (!username && !agent_code) {
      return res.status(400).json({ 
        error: 'Either username or agent_code is required' 
      });
    }

    // Call service layer for authentication
    const result = await agentService.loginAgent({
      merchant_code,
      username,
      agent_code,
      pin
    });

    // Return success response
    res.json(result);
    
  } catch (err: any) {
    // Handle authentication errors
    if (err.message === 'Invalid merchant code') {
      return res.status(401).json({ error: 'Invalid merchant code' });
    }
    if (err.message === 'Invalid agent credentials') {
      return res.status(401).json({ error: 'Agent not found or inactive' });
    }
    if (err.message === 'Invalid PIN') {
      return res.status(401).json({ error: 'Incorrect PIN' });
    }
    
    // Generic error
    res.status(500).json({ 
      error: 'Login failed', 
      details: err.message 
    });
  }
};
```

**Request Validation:**
- ✅ `merchant_code` is required
- ✅ `pin` is required
- ✅ Either `username` OR `agent_code` is required
- ❌ Missing fields return 400 Bad Request

---

### Step 7: Service Layer Authenticates User

**File:** `server/src/services/agentService.ts`

**Method:** `loginAgent()`

```typescript
import prisma from '../utils/prisma';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { Prisma } from '@prisma/client';

/**
 * Agent login for mobile app
 * Validates merchant_code (depot) + agent credentials + PIN
 * 
 * @param data - Login credentials
 * @returns Agent info + auth tokens
 * @throws Error if credentials invalid
 */
export const loginAgent = async (data: {
  merchant_code: string;  // HRE001
  username?: string;
  agent_code?: string;    // TMO014
  pin: string;            // 1234
}) => {
  const { merchant_code, username, agent_code, pin } = data;

  // ========================================
  // STEP 7.1: Validate Merchant Code
  // ========================================
  
  // Find depot by merchant code
  const depot = await prisma.tblDepots.findUnique({
    where: { merchant_code }
  });

  if (!depot) {
    throw new Error('Invalid merchant code');
  }

  // Depot found: depot-hre-001
  // Name: "Harare - Roadport"

  // ========================================
  // STEP 7.2: Find Agent in Depot
  // ========================================
  
  // Build query to find agent by username OR agent_code
  const where: Prisma.tblAgentsWhereInput = {
    depot_id: depot.id,      // Must be in the correct depot
    status: 'ACTIVE',        // Only active agents
    OR: [
      username ? { username } : {},
      agent_code ? { agent_code } : {}
    ].filter(obj => Object.keys(obj).length > 0)
  };

  const agent = await prisma.tblAgents.findFirst({ 
    where,
    include: { depot: true }  // Include depot info
  });

  if (!agent) {
    throw new Error('Invalid agent credentials');
  }

  // Agent found: agent-hre-001
  // ID: "agent-hre-001" (UUID String)
  // Full Name: "Tinashe Moyo"
  // Agent Code: "TMO014"
  // PIN (hashed): "$2b$10$..."

  // ========================================
  // STEP 7.3: Validate PIN with Bcrypt
  // ========================================
  
  // Compare provided PIN with stored bcrypt hash
  // Uses bcrypt.compare() - NOT direct string comparison!
  const isValidPin = await bcrypt.compare(pin, agent.pin || '');
  
  if (!isValidPin) {
    throw new Error('Invalid PIN');
  }

  // PIN validated ✅

  // ========================================
  // STEP 7.4: Generate JWT Tokens
  // ========================================
  
  const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
  const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret';

  // Access token (short-lived: 1 hour)
  const accessToken = jwt.sign(
    {
      agentId: agent.id,
      depotId: depot.id,
      role: 'AGENT',
      type: 'access'
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );

  // Refresh token (long-lived: 7 days)
  const refreshToken = jwt.sign(
    {
      agentId: agent.id,
      type: 'refresh'
    },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  // ========================================
  // STEP 7.5: Parse Agent Name
  // ========================================
  
  const nameParts = agent.full_name.split(' ');
  const firstName = nameParts[0] || '';
  const lastName = nameParts.slice(1).join(' ') || '';

  // ========================================
  // STEP 7.6: Return Response
  // ========================================
  
  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    agent: {
      id: agent.id,                      // UUID String (e.g., "agent-hre-001")
      agent_code: agent.agent_code,      // "TMO014"
      first_name: firstName,             // "Tinashe"
      last_name: lastName,               // "Moyo"
      role: 'AGENT',
      merchant_code: depot.merchant_code, // "HRE001"
      merchant_name: depot.name,          // "Harare - Roadport"
      depot_code: depot.merchant_code,    // "HRE001"
      depot_name: depot.name              // "Harare - Roadport"
    },
    message: 'Login successful'
  };
};
```

---

## 💾 Database Queries

### Query 1: Find Depot by Merchant Code

```sql
SELECT 
  id,
  merchant_code,
  name,
  location,
  created_at,
  updated_at
FROM "tblDepots"
WHERE merchant_code = 'HRE001';
```

**Result:**
```
id              | merchant_code | name               | location
----------------|---------------|--------------------|-----------------------
depot-hre-001   | HRE001        | Harare - Roadport  | Corner of Rotten Row...
```

### Query 2: Find Agent in Depot

```sql
SELECT 
  a.id,
  a.full_name,
  a.agent_code,
  a.username,
  a.pin,
  a.depot_id,
  a.status,
  d.merchant_code,
  d.name AS depot_name
FROM "tblAgents" a
INNER JOIN "tblDepots" d ON a.depot_id = d.id
WHERE a.depot_id = 'depot-hre-001'
  AND a.agent_code = 'TMO014'
  AND a.status = 'ACTIVE';
```

**Result:**
```
id            | full_name    | agent_code | pin                             | status
--------------|--------------|------------|---------------------------------|--------
agent-hre-001 | Tinashe Moyo | TMO014     | $2b$10$AuNz5qXIZqR1Msh3HqS1.Oe... | ACTIVE
```

**Note:** Agent ID is a UUID String format (e.g., "agent-hre-001"), not an integer.

### Query 3: Bcrypt PIN Comparison (In-Memory)

```typescript
// Compare plain text PIN with hash from database
const isValidPin = await bcrypt.compare(
  '1234',                                    // Plain text from request
  '$2b$10$AuNz5qXIZqR1Msh3HqS1.OeR...'      // Hash from database
);

// Returns: true ✅
```

**How Bcrypt Works:**
1. Extract salt from stored hash (`$2b$10$AuNz5qXIZqR1Msh3HqS1`)
2. Hash provided PIN with same salt
3. Compare resulting hash with stored hash
4. Return `true` if match, `false` otherwise

**Why This Is Secure:**
- Bcrypt is slow (intentionally) → prevents brute force
- Uses 10 salt rounds → computationally expensive
- Each hash is unique (different salt) → rainbow tables useless
- One-way function → cannot reverse hash to get PIN

---

## 🔐 Security Considerations

### 1. PIN Storage and Validation
```typescript
// ❌ WRONG: Storing plain text PIN
agent.pin = '1234';

// ✅ CORRECT: Storing bcrypt hash
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash('1234', 10);  // 10 salt rounds
agent.pin = hash;  // "$2b$10$..."

// ❌ WRONG: Direct comparison (NEVER works with bcrypt!)
if (agent.pin !== pin) {
  throw new Error('Invalid PIN');
}

// ✅ CORRECT: Use bcrypt.compare()
const isValidPin = await bcrypt.compare(pin, agent.pin);
if (!isValidPin) {
  throw new Error('Invalid PIN');
}
```

### 2. JWT Token Security

**Access Token (Short-Lived):**
```typescript
// Expires in 1 hour
const accessToken = jwt.sign(
  { agentId, depotId, role: 'AGENT', type: 'access' },
  JWT_SECRET,
  { expiresIn: '1h' }
);
```

**Refresh Token (Long-Lived):**
```typescript
// Expires in 7 days
const refreshToken = jwt.sign(
  { agentId, type: 'refresh' },
  JWT_REFRESH_SECRET,
  { expiresIn: '7d' }
);
```

**Token Storage:**
- ✅ Access token: Secure storage (flutter_secure_storage)
- ✅ Refresh token: Secure storage (flutter_secure_storage)
- ❌ Never store tokens in SharedPreferences (not encrypted)
- ❌ Never store tokens in local storage (web) without encryption

### 3. PIN Transmission

**Mobile to Backend:**
```typescript
// ✅ CORRECT: Send plain PIN over HTTPS
POST https://api.example.com/agents/login
{
  "merchant_code": "HRE001",
  "agent_code": "TMO014",
  "pin": "1234"  // Encrypted in transit via TLS
}

// ❌ WRONG: Hashing PIN client-side
// Backend cannot validate against stored hash
```

**Why Send Plain PIN?**
- HTTPS encrypts data in transit (TLS/SSL)
- Backend needs plain PIN to compare with bcrypt hash
- Client-side hashing would prevent bcrypt validation

### 4. Rate Limiting

**Backend Implementation:**
```typescript
import rateLimit from 'express-rate-limit';

// Limit login attempts
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 5,                     // 5 attempts
  message: 'Too many login attempts, please try again later'
});

// Apply to login route
app.use('/api/agents/login', loginLimiter);
```

### 5. Depot Validation

**Why Required:**
```typescript
// Agent TMO014 exists in HRE001 (Harare)
// Agent TMO014 does NOT exist in BYO001 (Bulawayo)

// ✅ CORRECT: Check depot_id matches merchant_code
const where = {
  depot_id: depot.id,  // depot-hre-001
  agent_code: 'TMO014'
};

// ❌ WRONG: Not checking depot
// Would allow TMO014 to login to any depot
const where = {
  agent_code: 'TMO014'
};
```

---

## ⚠️ Error Handling

### Mobile App Error Handling

```dart
Future<void> _submitPin() async {
  try {
    final response = await authRepo.login(
      merchantCode: widget.merchantCode,
      agentCode: widget.agentCode,
      pin: _pin,
    );
    
    // Success - navigate to home
    Navigator.of(context).pushReplacementNamed('/home');
    
  } on ApiError catch (error) {
    // API error with structured response
    String errorMessage = error.message;
    
    switch (error.type) {
      case ApiErrorType.networkError:
        errorMessage = 'No internet connection';
        break;
      case ApiErrorType.unauthorized:
        errorMessage = 'Invalid credentials';
        break;
      case ApiErrorType.timeout:
        errorMessage = 'Request timed out';
        break;
      default:
        errorMessage = error.message;
    }
    
    // Clear PIN and show error
    setState(() {
      _pin = '';
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
    
  } catch (e) {
    // Unexpected error
    setState(() {
      _pin = '';
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login failed: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

### Backend Error Responses

```typescript
// 400 Bad Request - Missing fields
{
  "error": "merchant_code and pin are required"
}

// 401 Unauthorized - Invalid merchant code
{
  "error": "Invalid merchant code"
}

// 401 Unauthorized - Agent not found
{
  "error": "Agent not found or inactive"
}

// 401 Unauthorized - Wrong PIN
{
  "error": "Incorrect PIN"
}

// 429 Too Many Requests - Rate limit exceeded
{
  "error": "Too many login attempts, please try again later"
}

// 500 Internal Server Error - Server issue
{
  "error": "Login failed",
  "details": "Database connection failed"
}
```

---

## 🧪 Testing Guide

### Test Credentials

**From Seed Data:**
```
Merchant Code: HRE001 (Harare depot)
Agent Code:    TMO014 (Tinashe Moyo)
PIN:           1234
```

### Manual Testing Steps

#### 1. Test Valid Login
```
Input:
- Merchant: HRE001
- Agent: TMO014
- PIN: 1234

Expected:
✅ Login successful
✅ Navigate to home screen
✅ Display "Welcome, Tinashe!"
✅ Access token saved
✅ Refresh token saved
```

#### 2. Test Invalid Merchant Code
```
Input:
- Merchant: XXX999
- Agent: TMO014
- PIN: 1234

Expected:
❌ Error: "Invalid merchant code"
❌ Stay on login screen
❌ PIN cleared
```

#### 3. Test Invalid Agent Code
```
Input:
- Merchant: HRE001
- Agent: XXX999
- PIN: 1234

Expected:
❌ Error: "Agent not found or inactive"
❌ Stay on login screen
❌ PIN cleared
```

#### 4. Test Invalid PIN
```
Input:
- Merchant: HRE001
- Agent: TMO014
- PIN: 9999

Expected:
❌ Error: "Incorrect PIN"
❌ Stay on login screen
❌ PIN cleared
```

#### 5. Test Rate Limiting
```
Input: 6 failed login attempts in < 15 minutes

Expected:
❌ Error: "Too many login attempts"
❌ HTTP 429 status
❌ Must wait 15 minutes
```

### API Testing with cURL

```bash
# Valid login
curl -X POST http://192.168.1.240:3000/api/agents/login \
  -H "Content-Type: application/json" \
  -d '{
    "merchant_code": "HRE001",
    "agent_code": "TMO014",
    "pin": "1234"
  }'

# Expected response
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "agent": {
    "id": "agent-hre-001",  // UUID String (not integer)
    "agent_code": "TMO014",
    "first_name": "Tinashe",
    "last_name": "Moyo",
    "role": "AGENT",
    "merchant_code": "HRE001",
    "merchant_name": "Harare - Roadport",
    "depot_code": "HRE001",
    "depot_name": "Harare - Roadport"
  },
  "message": "Login successful"
}
```

### Database Verification

```sql
-- Verify depot exists
SELECT * FROM "tblDepots" WHERE merchant_code = 'HRE001';

-- Verify agent exists and is active
SELECT * FROM "tblAgents" 
WHERE depot_id = 'depot-hre-001' 
  AND agent_code = 'TMO014' 
  AND status = 'ACTIVE';

-- Verify PIN hash (cannot reverse, but can test)
-- Use bcrypt.compare() in Node.js console
```

---

## 🔄 Token Refresh Flow

When access token expires (after 1 hour), use refresh token to get new tokens:

```typescript
POST /api/auth/refresh
Authorization: Bearer <refresh_token>

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "Token refreshed"
}
```

**Mobile Implementation:**
```dart
// Dio interceptor automatically refreshes token
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Access token expired, refresh it
      try {
        final newTokens = await _refreshToken();
        await _storageService.saveAuthTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken,
        );
        
        // Retry original request with new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
        final response = await _dio.request(
          options.path,
          options: Options(method: options.method, headers: options.headers),
        );
        
        handler.resolve(response);
      } catch (e) {
        // Refresh failed, logout user
        await _logout();
        handler.reject(err);
      }
    } else {
      handler.next(err);
    }
  }
}
```

---

## 📊 Performance Considerations

### Database Indexes

```sql
-- Index on merchant_code for fast depot lookup
CREATE UNIQUE INDEX idx_depots_merchant_code 
ON "tblDepots" (merchant_code);

-- Composite index on depot_id + agent_code for fast agent lookup
CREATE UNIQUE INDEX idx_agents_depot_agent 
ON "tblAgents" (depot_id, agent_code);

-- Index on status for filtering active agents
CREATE INDEX idx_agents_status 
ON "tblAgents" (status);
```

### Bcrypt Performance

```typescript
// 10 salt rounds ≈ 70-100ms per hash
// Good balance between security and speed
const saltRounds = 10;
const hash = await bcrypt.hash(pin, saltRounds);

// More rounds = more secure but slower
// 12 rounds ≈ 300ms (too slow for mobile)
// 8 rounds ≈ 30ms (too fast, less secure)
```

### Caching Considerations

```typescript
// DO NOT cache login responses
// Each login should validate against current DB state

// DO cache depot info (rarely changes)
const depotCache = new Map<string, Depot>();

// DO cache active agents list (refresh every 5 minutes)
const agentCache = new Map<string, Agent[]>();
```

---

## 📱 Offline Mode (Future Enhancement)

Currently, login requires network connectivity. Future enhancement for offline mode:

```dart
// Save last successful login credentials hash
Future<void> _saveOfflineCredentials(String merchantCode, String agentCode, String pinHash) async {
  await _prefs.setString('offline_merchant', merchantCode);
  await _prefs.setString('offline_agent', agentCode);
  await _prefs.setString('offline_pin_hash', pinHash);
  await _prefs.setInt('offline_agent_id', agentId);
}

// Validate offline login
Future<bool> _validateOfflineLogin(String merchantCode, String agentCode, String pin) async {
  final savedMerchant = _prefs.getString('offline_merchant');
  final savedAgent = _prefs.getString('offline_agent');
  final savedPinHash = _prefs.getString('offline_pin_hash');
  
  if (merchantCode != savedMerchant || agentCode != savedAgent) {
    return false;
  }
  
  // Compare PIN hash (bcrypt on mobile)
  return await bcrypt.compare(pin, savedPinHash);
}
```

---

## 🔍 Troubleshooting

### Issue: "Invalid merchant code"
**Cause:** Depot doesn't exist in database  
**Solution:** Verify merchant code in DB: `SELECT * FROM "tblDepots" WHERE merchant_code = 'HRE001'`

### Issue: "Agent not found or inactive"
**Cause:** Agent doesn't exist or status != 'ACTIVE'  
**Solution:** Check agent status: `SELECT status FROM "tblAgents" WHERE agent_code = 'TMO014'`

### Issue: "Incorrect PIN"
**Cause:** PIN doesn't match bcrypt hash  
**Solution:** Reset PIN in admin portal or verify hash: `bcrypt.compare('1234', hash)`

### Issue: Network timeout
**Cause:** Backend server not responding  
**Solution:** 
1. Check backend is running: `curl http://192.168.1.240:3000/api/health`
2. Check firewall settings
3. Verify mobile device on same network

### Issue: "Too many login attempts"
**Cause:** Rate limit exceeded (5 attempts in 15 minutes)  
**Solution:** Wait 15 minutes or clear rate limit cache

### Issue: "type 'Null' is not a subtype of type 'String' in type cast"
**Cause:** Backend not returning expected JWT tokens or agent data fields are missing  
**Solution:** Verify backend response includes `access_token`, `refresh_token`, and complete agent object with all required string fields

### Issue: "Session expired, please login again" (401 errors)
**Cause:** PIN validation using direct string comparison instead of bcrypt.compare()  
**Solution:** Fixed in agentService.ts - now uses `await bcrypt.compare(pin, agent.pin)`

---

## 📝 Changelog

### March 2, 2026 - Production Fixes
**Critical Bug Fixes:**
1. ✅ Fixed PIN validation in `agentService.ts`:
   - Changed from direct comparison (`agent.pin !== pin`) to bcrypt validation
   - Added `import bcrypt from 'bcrypt'`
   - Now correctly validates hashed PINs with `await bcrypt.compare(pin, agent.pin)`

2. ✅ Added JWT token generation:
   - Access token (1 hour expiration)
   - Refresh token (7 days expiration)
   - Tokens now properly returned in login response

3. ✅ Fixed agent ID data type mismatch:
   - Backend uses UUID strings (e.g., "agent-hre-001")
   - Changed mobile `AgentDto.id` from `int` to `String`
   - Updated `StorageService.saveAgentData()` to handle String IDs
   - Updated `StorageService.getAgentId()` to return `String?`

4. ✅ Enhanced response structure:
   - Split `full_name` into `first_name` and `last_name`
   - Added all required fields (`merchant_name`, `depot_code`, `depot_name`)
   - Response now matches mobile DTO expectations exactly

**Testing Status:**
- ✅ Backend returns 200 OK with proper JWT tokens
- ✅ Mobile successfully parses login response
- ✅ Authentication flow end-to-end functional

---

*Last Updated: March 2, 2026*  
*For questions or issues, contact the development team.*
