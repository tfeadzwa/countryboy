# Mobile App Authentication Flow

This document describes the 3-factor authentication system for the Countryboy mobile conductor app.

## 🔐 Authentication Factors

1. **Device Token** - Identifies the physical device (paired once)
2. **Merchant Code** - Identifies the depot/organization (entered daily)
3. **Conductor Credentials** - Identifies the agent (entered daily)

---

## 📏 Code Format Standards

All codes follow a **6-character format** for consistency and ease of use:

### Merchant Code (Depot Identifier)
- **Format:** `XXX###` (3 uppercase letters + 3 digits)
- **Purpose:** Identifies the depot/organization
- **Examples:**
  - `HRE001` - Harare Central Depot
  - `BYO001` - Bulawayo Main Depot
  - `GWE001` - Gweru Depot
  - `MUT001` - Mutare Depot

### Agent Code (Conductor Identifier)
- **Format:** `XXX###` (3 uppercase letters + 3 digits)
- **Purpose:** Agent initials + sequence number per depot
- **Examples:**
  - `TMO014` - Tapiwa Moyo, agent #014
  - `JDU003` - John Dube, agent #003
  - `KNC021` - Kelvin Ncube, agent #021

### Pairing Code (Device Setup)
- **Format:** `XXX###` or `XXX-###` (3 letters + 3 digits)
- **Purpose:** One-time device pairing
- **Examples:** `ABC234`, `K7M952`, `DEF-456`
- **Note:** No ambiguous characters (0, O, 1, I, L excluded)

**Benefits:**
- ✅ Only 6 characters - easy to type
- ✅ Human-readable and professional
- ✅ Consistent across all code types
- ✅ Easy to read on tickets and receipts

---

## 📱 Complete User Journey

### Phase 1: Device Setup (Once - Admin)

**Step 1: Admin Creates Device in Web Portal**
```http
POST /devices
Headers:
  Authorization: Bearer {{adminJWT}}
  x-depot-id: {{depotId}}
Body:
{
  "serial_number": "CB-POS-HRE-00014"
}

Response:
{
  "id": "abc-123-device-id",
  "serial_number": "CB-POS-HRE-00014",
  "token": "f7e3b8a1-92cd-4e12-a456-789012345678",  // Long token (stored, never shown to conductor)
  "pairing_code": "ABC-234",  // ⭐ 6-char code (shown ONCE to conductor)
  "paired": false,
  "depot_id": "depot-789"
}
```

**Step 2: Admin Gives Device + Pairing Code to Conductor**
- Admin physically hands the device to conductor
- Admin tells conductor the pairing code: "ABC-234" (or shows QR code)

---

### Phase 2: Device Pairing (Once - Conductor)

**Conductor opens app for first time on the device**

```http
POST /devices/pair
Body:
{
  "pairing_code": "ABC234"  // Can be entered with or without dash
}

Response:
{
  "device_id": "abc-123-device-id",
  "device_token": "f7e3b8a1-92cd-4e12-a456-789012345678",  // App stores this in secure storage
  "depot_id": "depot-789",
  "serial_number": "CB-POS-HRE-00014",
  "merchant_code": "HRE001"  // App displays this for conductor reference
}
```

**App Actions:**
1. ✅ Stores `device_token` in secure storage (encrypted)
2. ✅ Displays merchant_code to conductor for future reference
3. ✅ Marks device as paired
4. ✅ Shows success message
5. ✅ Proceeds to daily login screen

**Important:** Conductor NEVER sees or enters the long `device_token` again!

---

### Phase 3: Daily Login (Every Day - Conductor)

**Conductor opens app each morning**

```http
POST /agents/login
Body:
{
  "merchant_code": "HRE001",  // Depot identifier (6 chars: 3 letters + 3 digits)
  "agent_code": "TMO014",      // Agent initials + sequence (e.g., Tapiwa Moyo #014)
  "pin": "1234"                // 4-6 digit PIN
}

Response:
{
  "agent_id": "agent-456",
  "agent_code": "TMO014",
  "full_name": "Tapiwa Moyo",
  "depot_id": "depot-789",
  "depot_name": "Harare Central Depot",
  "merchant_code": "HRE001"
}
```

**App Actions:**
1. ✅ Stores agent session data
2. ✅ Unlocks trip/ticket screens
3. ✅ Ready for daily operations

---

### Phase 4: Sync Operations (Automatic)

**Conductor clicks "Sync" button during the day**

```http
POST /sync/push
Headers:
  Authorization: Bearer {{adminJWT}}  // Optional if separate admin auth exists
  x-device-token: {{storedDeviceToken}}  // ⭐ Automatically from secure storage
  x-depot-id: {{depotId}}  // From login response
Body:
{
  "trips": [...],
  "tickets": [...]
}
```

**App Actions:**
1. ✅ Reads `device_token` from secure storage automatically
2. ✅ Sends sync request with device token header
3. ✅ No manual entry needed by conductor

---

## 🎯 Token Lifecycle

### Pairing Code
- **Format:** `ABC-234` (3 letters + dash + 3 numbers)
- **Usage:** ONE-TIME only during device setup
- **Expiry:** After successful pairing (or can expire after 24 hours)
- **Storage:** App discards after pairing

### Device Token
- **Format:** UUID (`f7e3b8a1-92cd-4e12-a456-789012345678`)
- **Usage:** Every sync operation
- **Expiry:** Never (unless device is deactivated by admin)
- **Storage:** App secure storage (encrypted)

### Agent Session
- **Duration:** Until app is closed or conductor logs out
- **Renewal:** Daily login required
- **Status Check:** Only ACTIVE agents can log in

---

## 👤 Agent Status Management

Agents have lifecycle states managed by depot admins:

### Status Values

| Status | Meaning | Can Login? | Use Case |
|--------|---------|-----------|----------|
| `ACTIVE` | Currently working | ✅ Yes | Normal operations |
| `INACTIVE` | Temporarily not working | ❌ No | Vacation, medical leave, training |
| `SUSPENDED` | Disciplinary action | ❌ No | Investigation, pending review |
| `TERMINATED` | Former employee | ❌ No | Resigned, dismissed (audit trail) |

### Status Changes

**Admin updates agent status:**
```http
PUT /agents/:id
Headers:
  Authorization: Bearer {{adminJWT}}
  x-depot-id: {{depotId}}
Body:
{
  "status": "INACTIVE"
}
```

**Effect on Login:**
- Login attempt by non-ACTIVE agent returns error
- Agent must contact depot admin to reactivate

**Best Practices:**
- ✅ Never delete agent records (use TERMINATED for audit trail)
- ✅ Use INACTIVE for temporary absence
- ✅ Use SUSPENDED for pending investigations
- ✅ Change to TERMINATED when agent leaves permanently

---

## 🔄 Error Handling

### Invalid Pairing Code
```json
{
  "error": "Invalid pairing code"
}
```
→ Conductor re-enters code or contacts admin

### Device Already Paired
```json
{
  "error": "Device already paired"
}
```
→ Device cannot be paired again (prevents theft/reuse)

### Invalid Merchant Code
```json
{
  "error": "Invalid merchant code"
}
```
→ Conductor checks merchant code with admin

### Invalid PIN
```json
{
  "error": "Invalid PIN"
}
```
→ Conductor re-enters PIN or resets with admin

### Agent Not Active
```json
{
  "error": "Invalid agent credentials"
}
```
→ Agent status is INACTIVE, SUSPENDED, or TERMINATED  
→ Conductor contacts depot admin for reactivation

------

## 🛡️ Security Features

1. **Device Binding:** Token tied to specific device, can't be transferred
2. **One-Time Pairing:** Pairing code only works once
3. **Short Memorable Codes:** Easy for conductors, hard to guess (23^3 × 7^3 = 4.7M combinations)
4. **Depot Isolation:** Device can only access data from its assigned depot
5. **Agent Tracking:** All operations linked to specific conductor
6. **PIN Protection:** Daily authentication required

---

## 📊 Admin Portal Actions

### View Paired Devices
```http
GET /devices?depot_id={{depotId}}
Response:
[
  {
    "id": "...",
    "serial_number": "CB-POS-HRE-00014",
    "paired": true,
    "paired_at": "2026-03-01T08:30:00Z",
    "last_seen": "2026-03-01T14:22:00Z"
  }
]
```

### Revoke Device (Lost/Stolen)
```http
PUT /devices/:id
Body: { "status": "DEACTIVATED" }
```
Device token immediately invalidated, all sync requests fail.

---

## 💡 UI/UX Recommendations

### First-Time Setup Screen
```
┌─────────────────────────────────┐
│  Welcome to Countryboy!         │
│                                 │
│  Enter your pairing code:       │
│  ┌─────────────────────────┐   │
│  │  ABC-234                │   │
│  └─────────────────────────┘   │
│                                 │
│  [ Pair Device ]                │
└─────────────────────────────────┘
```

### Daily Login Screen
```
┌─────────────────────────────────┐
│  Harare Central Depot           │
│  Merchant Code: HRE001          │
│                                 │
│  Agent Code:                    │
│  ┌─────────────────────────┐   │
│  │  TMO014                 │   │
│  └─────────────────────────┘   │
│                                 │
│  PIN:                           │
│  ┌─────────────────────────┐   │
│  │  ••••                   │   │
│  └─────────────────────────┘   │
│                                 │
│  [ Login ]                      │
└─────────────────────────────────┘
```

### Sync Status
```
┌─────────────────────────────────┐
│  Tapiwa Moyo                    │
│  Device: CB-POS-HRE-00014 ✓     │
│                                 │
│  [ Sync Now ]                   │
│                                 │
│  Last Sync: 2 minutes ago       │
└─────────────────────────────────┘
```
