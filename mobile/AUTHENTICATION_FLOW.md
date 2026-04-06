# Backend Authentication Flow - Countryboy Mobile App

## 📋 Overview

The mobile app has a **2-step authentication process**:

1. **Device Pairing** (One-time setup) - Links the mobile device to a depot
2. **Agent Login** (Daily) - Authenticates the conductor for each work session

Both endpoints are **public** (no authentication required) to allow initial access.

---

## 🔐 Authentication Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  MOBILE APP FLOW                        │
└─────────────────────────────────────────────────────────┘
                            │
                            │ First Time
                            ▼
              ┌─────────────────────────┐
              │  1. DEVICE PAIRING      │
              │  POST /devices/pair     │
              │  Body: { pairing_code } │
              └─────────────────────────┘
                            │
                            │ Returns: device_token (UUID)
                            │ Stored securely in app
                            ▼
              ┌─────────────────────────┐
              │  2. AGENT LOGIN         │
              │  POST /agents/login     │
              │  Body: {                │
              │    merchant_code,       │
              │    agent_code,          │
              │    pin                  │
              │  }                      │
              └─────────────────────────┘
                            │
                            │ Returns: agent session data
                            │ Conductor can now work
                            ▼
              ┌─────────────────────────┐
              │  App Ready!             │
              │  Can issue tickets      │
              └─────────────────────────┘
```

---

## 🎫 1. Device Pairing (One-Time Setup)

### Endpoint
```
POST /devices/pair
```
**No authentication required** - Public endpoint

### Database Table: `tblDevices`

```prisma
model tblDevices {
  id            String   @id @default(uuid())
  serial_number String   @unique
  token         String?  @unique           // Long UUID for API auth
  pairing_code  String?  @unique           // Short 6-char code (ABC234)
  paired        Boolean  @default(false)   // Pairing status
  paired_at     DateTime?                  // When paired
  depot_id      String                     // Which depot owns this device
  last_seen     DateTime?
  app_version   String?
  sync_errors   Int      @default(0)
  created_at    DateTime @default(now())
  updated_at    DateTime @updatedAt
  
  depot         tblDepots @relation(fields: [depot_id], references: [id])
}
```

### How Pairing Code is Created

Admin creates device in web portal:

**File**: [deviceService.ts](server/src/services/deviceService.ts)
```typescript
export const createDevice = async (depotId: string, data: { serial_number: string }) => {
  const token = generateDeviceToken();        // Long UUID: "tok-a1b2c3d4-e5f6..."
  const pairing_code = generatePairingCode(); // Short code: "ABC234"
  
  return prisma.tblDevices.create({
    data: { 
      serial_number: data.serial_number,
      depot_id: depotId, 
      token,                    // ← Generated UUID token
      pairing_code,             // ← Generated 6-char code
      paired: false             // ← Not paired yet
    }
  });
};
```

**Admin gives the pairing code (e.g., "ABC234") to the conductor.**

### Mobile App Pairing Flow

Conductor enters pairing code in mobile app → calls:

**Route**: [device.ts](server/src/routes/device.ts#L12)
```typescript
// Public endpoint - no auth middleware
router.post('/pair', deviceController.pair);
```

**Controller**: [deviceController.ts](server/src/controllers/deviceController.ts#L73-L94)
```typescript
export const pair = async (req: Request, res: Response) => {
  try {
    const { pairing_code } = req.body;
    
    if (!pairing_code) {
      return res.status(400).json({ error: 'Pairing code is required' });
    }

    const result = await deviceService.pairDevice(pairing_code);
    res.json(result);
  } catch (err: any) {
    if (err.message === 'Invalid pairing code') {
      return res.status(404).json({ error: 'Invalid pairing code' });
    }
    if (err.message === 'Device already paired') {
      return res.status(409).json({ error: 'Device already paired' });
    }
    res.status(500).json({ error: 'Failed to pair device', details: err });
  }
};
```

**Service**: [deviceService.ts](server/src/services/deviceService.ts#L26-L58)
```typescript
export const pairDevice = async (pairingCode: string) => {
  // 1. Find device by pairing code
  const device = await prisma.tblDevices.findUnique({
    where: { pairing_code: pairingCode.toUpperCase().replace('-', '') },
    include: { depot: true }
  });

  // 2. Validate device exists
  if (!device) {
    throw new Error('Invalid pairing code');
  }

  // 3. Check if already paired
  if (device.paired) {
    throw new Error('Device already paired');
  }

  // 4. Mark device as paired
  const updated = await prisma.tblDevices.update({
    where: { id: device.id },
    data: { 
      paired: true,           // ← Set to true
      paired_at: new Date()   // ← Record pairing time
    }
  });

  // 5. Return device token (UUID) to mobile app
  return {
    device_id: updated.id,
    device_token: updated.token,      // ← This is the long UUID
    depot_id: updated.depot_id,
    serial_number: updated.serial_number,
    merchant_code: device.depot.merchant_code
  };
};
```

### What Happens

1. **Admin creates device** → Server generates:
   - `token`: Long UUID (e.g., `tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890`)
   - `pairing_code`: Short 6-char code (e.g., `ABC234`)
   - `paired`: `false`

2. **Admin gives pairing code** to conductor

3. **Conductor enters `ABC234`** in mobile app

4. **Server finds device** with `pairing_code = "ABC234"`

5. **Server validates**:
   - Device exists? ✓
   - Not already paired? ✓

6. **Server updates device**:
   - `paired = true`
   - `paired_at = now()`

7. **Server returns `device_token`** (UUID) to app

8. **Mobile app stores `device_token`** in secure storage

9. **Pairing complete!** Device linked to depot

### Request/Response Example

**Request**:
```http
POST /devices/pair
Content-Type: application/json

{
  "pairing_code": "ABC234"
}
```

**Response (Success)**:
```json
{
  "device_id": "device-hre-003",
  "device_token": "tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345",
  "depot_id": "depot-hre-001",
  "serial_number": "HRE-DEV-003",
  "merchant_code": "HRE001"
}
```

**Response (Error - Invalid Code)**:
```json
{
  "error": "Invalid pairing code"
}
```

**Response (Error - Already Paired)**:
```json
{
  "error": "Device already paired"
}
```

---

## 👤 2. Agent Login (Daily Authentication)

### Endpoint
```
POST /agents/login
```
**No authentication required** - Public endpoint

### Database Table: `tblAgents`

```prisma
model tblAgents {
  id          String   @id @default(uuid())
  full_name   String
  username    String?                      // Optional - for web portal
  agent_code  String                       // Unique code (TMO014)
  pin         String?                      // 4-6 digit PIN (1234)
  depot_id    String
  status      String   @default("ACTIVE")  // ACTIVE, INACTIVE, etc.
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt
  
  depot        tblDepots @relation(fields: [depot_id], references: [id])
  trips        tblTrips[]
  tickets      tblTickets[]
  
  @@unique([depot_id, username])
  @@unique([depot_id, agent_code])  // ← Unique per depot
}
```

### How Agent PIN is Created

Admin creates agent in web portal:

**File**: [agentService.ts](server/src/services/agentService.ts)
```typescript
export const createAgent = async (depotId: string, data: { 
  full_name: string; 
  username?: string; 
  agent_code: string;
  pin?: string;           // ← PIN stored as-is (plain text in dev)
  status?: string;
}) => {
  return prisma.tblAgents.create({
    data: { 
      full_name: data.full_name,
      username: data.username,
      agent_code: data.agent_code,  // ← e.g., "TMO014"
      pin: data.pin,                 // ← e.g., "1234"
      depot_id: depotId,
      status: data.status || 'ACTIVE'
    }
  });
};
```

**Note**: Currently PINs are stored in **plain text**. For production, you should hash them using bcrypt like you do for passwords.

### Mobile App Login Flow

**UI Flow**: Two-step process for better UX

**Step 1 - Agent Identification**: Conductor enters merchant_code + agent_code
- Validates format (6 characters each)
- Remembers merchant_code for future logins
- Proceeds to Step 2

**Step 2 - PIN Entry**: Displays agent name, conductor enters PIN
- Shows personalized welcome with agent's full name
- Large numeric keypad (72x72dp buttons)
- 4-6 digit PIN entry
- Sends all three fields to API

**API Call**: Both steps' data sent in single request after Step 2

Conductor opens app daily → enters credentials → calls:

**Route**: [agent.ts](server/src/routes/agent.ts#L12)
```typescript
// Public endpoint - no auth middleware
router.post('/login', agentController.login);
```

**Controller**: [agentController.ts](server/src/controllers/agentController.ts#L74-L111)
```typescript
export const login = async (req: Request, res: Response) => {
  try {
    const { merchant_code, username, agent_code, pin } = req.body;

    // 1. Validate required fields
    if (!merchant_code || !pin) {
      return res.status(400).json({ 
        error: 'merchant_code and pin are required' 
      });
    }

    if (!username && !agent_code) {
      return res.status(400).json({ 
        error: 'Either username or agent_code is required' 
      });
    }

    // 2. Call service to validate credentials
    const result = await agentService.loginAgent({
      merchant_code,
      username,
      agent_code,
      pin
    });

    res.json(result);
  } catch (err: any) {
    // 3. Handle specific errors
    if (err.message === 'Invalid merchant code') {
      return res.status(404).json({ error: 'Invalid merchant code' });
    }
    if (err.message === 'Invalid agent credentials') {
      return res.status(404).json({ error: 'Agent not found' });
    }
    if (err.message === 'Invalid PIN') {
      return res.status(401).json({ error: 'Invalid PIN' });
    }
    res.status(500).json({ error: 'Login failed', details: err });
  }
};
```

**Service**: [agentService.ts](server/src/services/agentService.ts#L39-L91)
```typescript
export const loginAgent = async (data: {
  merchant_code: string;
  username?: string;
  agent_code?: string;
  pin: string;
}) => {
  const { merchant_code, username, agent_code, pin } = data;

  // 1. Validate merchant code (depot)
  const depot = await prisma.tblDepots.findUnique({
    where: { merchant_code }  // ← Find depot by merchant code
  });

  if (!depot) {
    throw new Error('Invalid merchant code');
  }

  // 2. Find agent by username OR agent_code
  const where: Prisma.tblAgentsWhereInput = {
    depot_id: depot.id,       // ← Must be in this depot
    status: 'ACTIVE',         // ← Must be active
    OR: [
      username ? { username } : {},
      agent_code ? { agent_code } : {}
    ].filter(obj => Object.keys(obj).length > 0)
  };

  const agent = await prisma.tblAgents.findFirst({ where });

  if (!agent) {
    throw new Error('Invalid agent credentials');
  }

  // 3. Validate PIN (plain text comparison in dev)
  if (agent.pin !== pin) {
    throw new Error('Invalid PIN');
  }

  // 4. Return agent session data
  return {
    agent_id: agent.id,
    agent_code: agent.agent_code,
    full_name: agent.full_name,
    depot_id: depot.id,
    depot_name: depot.name,
    merchant_code: depot.merchant_code
  };
};
```

### Login Validation Steps

1. **Validate merchant code**:
   - Lookup `tblDepots` where `merchant_code = "HRE001"`
   - If not found → `404 Invalid merchant code`

2. **Find agent**:
   - In that depot (`depot_id = depot.id`)
   - With status `ACTIVE`
   - Matching `agent_code = "TMO014"` OR `username = "tinashe"`

3. **Validate PIN**:
   - Compare `agent.pin === pin` (plain text)
   - If mismatch → `401 Invalid PIN`

4. **Return session**:
   - Agent info
   - Depot info
   - No JWT token (session managed by app)

### Request/Response Example

**Request**:
```http
POST /agents/login
Content-Type: application/json

{
  "merchant_code": "HRE001",
  "agent_code": "TMO014",
  "pin": "1234"
}
```

**Response (Success)**:
```json
{
  "agent_id": "agent-hre-001",
  "agent_code": "TMO014",
  "full_name": "Tinashe Moyo",
  "depot_id": "depot-hre-001",
  "depot_name": "Harare Main Terminal",
  "merchant_code": "HRE001"
}
```

**Response (Error - Invalid Merchant)**:
```json
{
  "error": "Invalid merchant code"
}
```

**Response (Error - Agent Not Found)**:
```json
{
  "error": "Agent not found"
}
```

**Response (Error - Wrong PIN)**:
```json
{
  "error": "Invalid PIN"
}
```

---

## 🔑 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE TABLES                          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   tblDepots      │       │   tblDevices     │       │   tblAgents      │
├──────────────────┤       ├──────────────────┤       ├──────────────────┤
│ id               │◄──────│ depot_id (FK)    │       │ id               │
│ merchant_code    │       │ serial_number    │       │ agent_code       │
│ name             │       │ token (UUID)     │       │ pin              │
│ location         │       │ pairing_code     │       │ full_name        │
└──────────────────┘       │ paired (bool)    │       │ depot_id (FK)────┼─┐
                           │ paired_at        │       │ status           │ │
                           └──────────────────┘       └──────────────────┘ │
                                                                            │
                           ┌─────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                       AUTHENTICATION FLOW                        │
└──────────────────────────────────────────────────────────────────┘

STEP 1: DEVICE PAIRING
─────────────────────────────────────────────────────────────────
Admin → Creates device → Server generates:
                         • token: "tok-f6a7b8c9-..."
                         • pairing_code: "ABC234"
                         • paired: false

Conductor → Enters "ABC234" → POST /devices/pair
                            → Server finds device
                            → Sets paired = true
                            → Returns device_token (UUID)

Mobile App → Stores device_token in secure storage
          → Remembers merchant_code: "HRE001"


STEP 2: AGENT LOGIN (Two-Screen UI Flow)
─────────────────────────────────────────────────────────────────

SCREEN 1: Agent Identification
─────────────────────────────────
Conductor → Enters merchant_code: "HRE001"
         → Enters agent_code: "TMO014"
         → Taps "Continue"
         
App → Validates format (6 chars each)
   → Stores codes temporarily
   → Navigates to PIN screen


SCREEN 2: PIN Entry
─────────────────────────────────
App → Displays: "Welcome, Tinashe Moyo"
   → Shows large numeric keypad

Conductor → Enters PIN: "1234"
         → Taps checkmark or auto-submits

App → Combines all data → Calls API:
      POST /agents/login {
        merchant_code: "HRE001",
        agent_code: "TMO014",
        pin: "1234"
      }

Server → 1. Find depot where merchant_code = "HRE001"
      → 2. Find agent where:
             • depot_id = depot.id
             • agent_code = "TMO014"
             • status = "ACTIVE"
      → 3. Compare pin: agent.pin === "1234"
      → 4. Return agent session data

Mobile App → Stores session in memory
          → Ready to issue tickets!
```

---

## 📝 Summary

### Pairing Code (One-Time)
- **Where stored**: `tblDevices.pairing_code`
- **Format**: 6 characters (e.g., `ABC234`)
- **Created by**: Admin in web portal when registering device
- **Used once**: Mobile app pairs device using this code
- **Returns**: Long `device_token` (UUID) for future API calls
- **Endpoint**: `POST /devices/pair`
- **Controller**: [deviceController.ts:73](server/src/controllers/deviceController.ts#L73)
- **Service**: [deviceService.ts:26](server/src/services/deviceService.ts#L26)

### Agent PIN (Daily)
- **Where stored**: `tblAgents.pin`
- **Format**: 4-6 digits (e.g., `1234`)
- **Created by**: Admin when creating agent
- **Used daily**: Conductor logs in with merchant_code + agent_code + PIN
- **Returns**: Agent session data (no token needed)
- **Endpoint**: `POST /agents/login`
- **Controller**: [agentController.ts:74](server/src/controllers/agentController.ts#L74)
- **Service**: [agentService.ts:39](server/src/services/agentService.ts#L39)

### Key Validation Logic

**Device Pairing**:
1. Find device by `pairing_code`
2. Check `paired === false`
3. Set `paired = true`, `paired_at = now()`
4. Return `device_token`

**Agent Login**:
1. Find depot by `merchant_code`
2. Find agent by `agent_code` in that depot
3. Check `status === "ACTIVE"`
4. Compare `pin` (plain text)
5. Return agent session

---

## 🔒 Security Recommendations

### Current State (Development)
- ✅ Pairing codes are one-time use
- ✅ Device tokens are UUIDs (strong)
- ⚠️ PINs stored in **plain text**
- ⚠️ No session tokens/JWT
- ⚠️ No rate limiting on login

### Production Recommendations
1. **Hash PINs** using bcrypt (like passwords)
2. **Add JWT tokens** for agent sessions
3. **Rate limit** login attempts (5 tries, then lockout)
4. **Expire pairing codes** after 24 hours
5. **Add device fingerprinting** to detect stolen devices
6. **Log all login attempts** for security audit
7. **Require PIN change** on first login

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026  
**Related Docs**: [API_INTEGRATION.md](API_INTEGRATION.md), [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
