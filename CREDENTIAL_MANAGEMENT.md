# Credential Management & Code Distribution

This document explains how merchant codes, agent codes, and device pairing codes are created, assigned, and distributed in the Countryboy system.

## 📋 Table of Contents
- [Code Types](#code-types)
- [Admin Workflow](#admin-workflow)
- [Conductor Workflow](#conductor-workflow)
- [Code Formats](#code-formats)
- [Security Model](#security-model)

---

## 🔑 Code Types

### 1. Merchant Code
- **Purpose:** Identifies the depot/bus company
- **Format:** `CITY001` (3 letters + 3 numbers)
- **Examples:** `HRE001`, `BYO001`, `MUT001`
- **Created by:** Admin when creating a new depot
- **Stored in:** `tblDepots.merchant_code`
- **Uniqueness:** Globally unique across all depots
- **Used for:** Agent login, device pairing association

### 2. Agent Code
- **Purpose:** Identifies individual conductor/ticket agent
- **Format:** `IIF999` (3 initials + 3 numbers)
- **Examples:** `TMO014` (Tinashe Moyo #14), `FNC015` (Farai Ncube #15)
- **Created by:** Admin when adding a new agent
- **Stored in:** `tblAgents.agent_code`
- **Uniqueness:** Unique within each depot (enforced by database)
- **Used for:** Agent login identification

### 3. Agent PIN
- **Purpose:** Quick authentication for daily login
- **Format:** 4-6 digit numeric code
- **Examples:** `1234`, `9876`
- **Created by:** Admin assigns OR system auto-generates
- **Stored in:** `tblAgents.pin` (bcrypt hashed)
- **Uniqueness:** Not required to be unique
- **Used for:** Daily authentication after entering codes

### 4. Device Pairing Code
- **Purpose:** One-time setup to link mobile app to device record
- **Format:** `ABC123` (3 letters + 3 numbers, no ambiguous chars)
- **Examples:** `ABC234`, `XYZ789`
- **Created by:** Backend auto-generates when admin registers device
- **Stored in:** `tblDevices.pairing_code`
- **Uniqueness:** Globally unique
- **Used for:** Initial device setup only (becomes invalid after pairing)

### 5. Device Token
- **Purpose:** Long-term API authentication token
- **Format:** UUID v4 (`tok-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- **Examples:** `tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345`
- **Created by:** Backend auto-generates during device registration
- **Stored in:** `tblDevices.token` (server) & secure storage (mobile)
- **Uniqueness:** Globally unique
- **Used for:** All API requests after device is paired

---

## 👨‍💼 Admin Workflow

### Step 1: Create Depot
**Action:** Admin creates a new bus depot in web portal

**Admin Form:**
```
Create New Depot
├─ Name: "Harare - Roadport"
├─ Location: "Corner of Rotten Row & 5th St, Harare"
└─ Merchant Code: "HRE001" ← Admin assigns
```

**Database Result:**
```sql
INSERT INTO "tblDepots" (
  id, merchant_code, name, location
) VALUES (
  'depot-hre-001', 'HRE001', 'Harare - Roadport', 'Corner...'
);
```

**Constraint:** Merchant code must be unique across all depots.

---

### Step 2: Create Agent/Conductor
**Action:** Admin adds a new conductor to the depot

**Admin Form:**
```
Add New Agent
├─ Full Name: "Tinashe Moyo"
├─ Depot: [Dropdown] "Harare - Roadport (HRE001)"
├─ Agent Code: "TMO014" ← Admin assigns
├─ PIN: "1234" ← Admin assigns OR auto-generate
└─ Status: "ACTIVE"
```

**Database Result:**
```sql
INSERT INTO "tblAgents" (
  id, full_name, agent_code, depot_id, pin, status
) VALUES (
  'agent-hre-001', 'Tinashe Moyo', 'TMO014', 
  'depot-hre-001', '$2b$10$...hash...', 'ACTIVE'
);
```

**Constraint:** Agent code must be unique within the depot.

**Business Rules:**
- Agent code should follow initials + number pattern for easy memorization
- PIN should be memorable for conductor but not easily guessable
- Admin may allow conductor to set their own PIN after first login

---

### Step 3: Register Device
**Action:** Admin registers a new POS terminal device

**Admin Form:**
```
Register New Device
├─ Serial Number: "HRE-DEV-003" ← Admin enters
├─ Depot: [Dropdown] "Harare - Roadport (HRE001)"
└─ [Save Button]
```

**Backend Auto-Generates:**
```typescript
// In deviceService.createDevice()
const token = generateDeviceToken();        // "tok-f6a7b8c9-d0e1..."
const pairing_code = generatePairingCode(); // "ABC234"
```

**Database Result:**
```sql
INSERT INTO "tblDevices" (
  id, serial_number, token, pairing_code, 
  depot_id, paired
) VALUES (
  'device-hre-003', 'HRE-DEV-003', 
  'tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345',
  'ABC234', 'depot-hre-001', false
);
```

**Result:** Admin sees the pairing code on screen to give to conductor.

---

### Step 4: Distribute Credentials
**Action:** Admin provides credentials to conductor

**Method 1: Paper Slip**
```
┌─────────────────────────────────────┐
│     CONDUCTOR CREDENTIALS           │
│     Device: HRE-DEV-003             │
├─────────────────────────────────────┤
│  📱 Device Pairing Code: ABC234     │
│  🏢 Merchant Code:       HRE001     │
│  👤 Agent Code:          TMO014     │
│  🔑 PIN:                 1234       │
├─────────────────────────────────────┤
│  Keep this secure!                  │
│  Pairing code is one-time use only │
└─────────────────────────────────────┘
```

**Method 2: SMS/WhatsApp** (Less secure)
```
Your Countryboy credentials:
Pairing: ABC234
Merchant: HRE001
Agent: TMO014
PIN: 1234

Use pairing code once to setup device.
Then login daily with merchant + agent + PIN.
```

---

## 📱 Conductor Workflow

### First Time: Device Pairing

**Step 1:** Conductor receives POS terminal and credentials from admin

**Step 2:** Launch Countryboy app (first launch shows pairing screen)

**Step 3:** Enter pairing code
```
┌──────────────────────────────┐
│      Device Pairing          │
│                              │
│  [ABC234          ] 🔄       │
│   ▲ Paste                    │
│                              │
│  [   Pair Device   ]         │
└──────────────────────────────┘
```

**Step 4:** Backend validates and pairs device
```typescript
POST /api/devices/pair
Body: {
  pairing_code: "ABC234",
  device_name: "Samsung SM A556E",
  device_model: "SM A556E",
  app_version: "1.0.0+1"
}

Response: {
  device_token: "tok-f6a7b8c9...",
  merchant_code: "HRE001",
  message: "Device paired successfully"
}
```

**Result:**
- Device token saved securely on mobile app
- Merchant code saved in app preferences
- Pairing code becomes invalid (cannot be reused)
- Database updated: `paired: true`, `paired_at: now()`

---

### Daily Login

**Every Day:** Conductor logs in with codes + PIN

**Step 1: Enter Identification Codes**
```
┌──────────────────────────────┐
│      Agent Login             │
│      Step 1 of 2             │
│                              │
│  Merchant Code               │
│  [HRE001          ]          │
│                              │
│  Agent Code                  │
│  [TMO014          ]          │
│                              │
│  [     Continue     ]        │
└──────────────────────────────┘
```

**Step 2: Enter PIN**
```
┌──────────────────────────────┐
│      Enter PIN               │
│      Step 2 of 2             │
│                              │
│  [●] [●] [●] [●]            │
│                              │
│  [1] [2] [3]                │
│  [4] [5] [6]                │
│  [7] [8] [9]                │
│  [⌫] [0] [✓]                │
└──────────────────────────────┘
```

**Backend Authentication:**
```typescript
POST /api/agents/login
Headers: {
  Authorization: "Bearer tok-f6a7b8c9..." // Device token
}
Body: {
  merchant_code: "HRE001",
  agent_code: "TMO014",
  pin: "1234"
}

Response: {
  access_token: "eyJhbGc...",
  refresh_token: "eyJhbGc...",
  agent: {
    id: 123,
    agent_code: "TMO014",
    first_name: "Tinashe",
    last_name: "Moyo",
    merchant_code: "HRE001",
    merchant_name: "Harare - Roadport",
    ...
  },
  message: "Login successful"
}
```

**Result:**
- Access token saved (for API calls)
- Refresh token saved (for token renewal)
- Agent data cached locally
- Navigate to home screen

---

## 📐 Code Formats

### Merchant Code Rules
```
Format: CITY001
├─ CITY: 3 uppercase letters (city abbreviation)
│   Examples: HRE, BYO, MUT, KWE, GWE
├─ 001: 3 digits (depot number in that city)
│   Range: 001-999
└─ Total Length: 6 characters

Examples:
✅ HRE001 - Harare depot #1
✅ BYO002 - Bulawayo depot #2
✅ MUT001 - Mutare depot #1
❌ HRE1   - Too short
❌ hre001 - Must be uppercase
❌ H1234  - Wrong format
```

### Agent Code Rules
```
Format: IIF999
├─ IIF: 3 uppercase letters (agent initials)
│   Examples: TMO, FNC, RCH, NDU
├─ 999: 3 digits (agent number)
│   Range: 001-999
└─ Total Length: 6 characters

Examples:
✅ TMO014 - Tinashe Moyo #14
✅ FNC015 - Farai Ncube #15
✅ RCH016 - Rumbidzai Chuma #16
❌ TM14   - Too short
❌ tmo014 - Must be uppercase
❌ T12345 - Wrong format

Business Logic:
- Use first 3 letters of first + last name
- If duplicate, use first + middle initial
- Number sequentially within depot
```

### Pairing Code Rules
```
Format: ABC123
├─ ABC: 3 uppercase letters
│   Excluded: O, I (look like 0, 1)
│   Allowed: ABCDEFGHJKLMNPQRSTUVWXYZ (23 letters)
├─ 123: 3 digits
│   Excluded: 0, 1 (look like O, I)
│   Allowed: 23456789 (7 digits)
└─ Total Length: 6 characters

Examples:
✅ ABC234 - Valid
✅ XYZ789 - Valid
✅ DEF456 - Valid
❌ ABO123 - Contains 'O'
❌ AB1234 - Wrong length
❌ abc234 - Must be uppercase

Optional Format: ABC-123 (with dash for readability)
```

### PIN Rules
```
Format: 4-6 digits
├─ Length: Minimum 4, maximum 6
├─ Characters: Digits 0-9 only
└─ Storage: Bcrypt hashed

Examples:
✅ 1234    - Valid (4 digits)
✅ 123456  - Valid (6 digits)
✅ 9876    - Valid
❌ 123     - Too short (< 4)
❌ 1234567 - Too long (> 6)
❌ 12ab    - Must be digits only

Business Rules:
- Avoid obvious patterns: 1234, 0000, 1111
- Don't use birthdays or phone numbers
- Allow conductor to change PIN after first login
```

---

## 🔒 Security Model

### Credential Hierarchy
```
Device Pairing (One-Time)
    ↓ Results in
Device Token (Persistent)
    ↓ Used with
Merchant Code + Agent Code + PIN (Daily Login)
    ↓ Results in
Access Token (Session)
```

### Security Properties

**1. Device Pairing Code**
- ✅ One-time use only
- ✅ Becomes invalid after successful pairing
- ✅ Cannot be reused even if leaked
- ✅ Admin must "unpair" device to generate new code
- ⚠️ Physical security: Keep paper slip secure until pairing complete

**2. Device Token**
- ✅ Stored in secure device storage (flutter_secure_storage)
- ✅ Never logged or displayed
- ✅ Tied to specific device hardware
- ✅ Cannot be transferred between devices
- ✅ Rotated if device is unpaired and re-paired

**3. Merchant Code + Agent Code**
- ⚠️ Must be memorized or securely stored by conductor
- ⚠️ Can be shoulder-surfed during entry
- ⚠️ If leaked, attacker still needs PIN
- ✅ Combined with PIN provides two-factor auth

**4. PIN**
- ✅ Bcrypt hashed (never stored in plain text)
- ✅ 10 salt rounds (computationally expensive to brute force)
- ✅ Masked during entry (shown as dots)
- ⚠️ Conductor must memorize (not written down)
- ⚠️ Limited to 4-6 digits (convenience vs security trade-off)

**5. Access Token (JWT)**
- ✅ Short-lived (typically 1 hour)
- ✅ Signed with server secret (cannot be forged)
- ✅ Contains agent ID, depot ID, roles
- ✅ Automatically refreshed with refresh token
- ✅ Invalidated on logout

**6. Refresh Token**
- ✅ Long-lived (typically 7 days)
- ✅ Stored securely with device token
- ✅ Used to obtain new access tokens
- ✅ Invalidated on logout or device unpair

---

## 🔄 Re-pairing Scenarios

### When Re-pairing is Required
1. **App Uninstalled:** All local data lost (device token, merchant code, agent data)
2. **Device Factory Reset:** All app data wiped
3. **Device Lost/Stolen:** Admin disables device, issues new one
4. **Device Hardware Failure:** Replacing physical POS terminal

### Re-pairing Process

**Step 1: Admin Unpairs Device**
```
Admin Portal → Devices → [Select Device] → "Unpair Device"

Result:
- paired: false
- paired_at: null
- pairing_code: "NEW456" (newly generated)
- device_name: null
- device_model: null
- app_version: null
- last_seen: null
```

**Step 2: Admin Provides New Pairing Code**
```
Admin gives conductor new slip:
┌─────────────────────────────────────┐
│     NEW PAIRING CODE                │
│     Device: HRE-DEV-003             │
├─────────────────────────────────────┤
│  📱 New Pairing Code: NEW456        │
│                                     │
│  Use this to re-pair your device.   │
│  Your merchant code, agent code,    │
│  and PIN remain the same.           │
└─────────────────────────────────────┘
```

**Step 3: Conductor Re-pairs**
- Open app (shows pairing screen since no device token)
- Enter new pairing code: `NEW456`
- Device pairs successfully
- Login with existing merchant code, agent code, PIN

---

## 📊 Database Schema Reference

### tblDepots
```sql
CREATE TABLE "tblDepots" (
  id            TEXT PRIMARY KEY DEFAULT uuid(),
  merchant_code TEXT UNIQUE NOT NULL,  -- HRE001, BYO001
  name          TEXT NOT NULL,          -- "Harare - Roadport"
  location      TEXT,
  created_at    TIMESTAMP DEFAULT now(),
  updated_at    TIMESTAMP DEFAULT now()
);
```

### tblAgents
```sql
CREATE TABLE "tblAgents" (
  id          TEXT PRIMARY KEY DEFAULT uuid(),
  full_name   TEXT NOT NULL,              -- "Tinashe Moyo"
  agent_code  TEXT NOT NULL,              -- TMO014
  pin         TEXT,                       -- Bcrypt hash
  depot_id    TEXT REFERENCES tblDepots(id),
  status      TEXT DEFAULT 'ACTIVE',
  created_at  TIMESTAMP DEFAULT now(),
  updated_at  TIMESTAMP DEFAULT now(),
  UNIQUE(depot_id, agent_code)           -- Agent code unique per depot
);
```

### tblDevices
```sql
CREATE TABLE "tblDevices" (
  id            TEXT PRIMARY KEY DEFAULT uuid(),
  serial_number TEXT UNIQUE NOT NULL,     -- HRE-DEV-003
  token         TEXT UNIQUE,               -- tok-f6a7b8c9-d0e1...
  pairing_code  TEXT UNIQUE,               -- ABC234
  paired        BOOLEAN DEFAULT false,
  paired_at     TIMESTAMP,
  depot_id      TEXT REFERENCES tblDepots(id),
  device_name   TEXT,                      -- "Samsung SM A556E"
  device_model  TEXT,                      -- "SM A556E"
  app_version   TEXT,                      -- "1.0.0+1"
  last_seen     TIMESTAMP,
  created_at    TIMESTAMP DEFAULT now(),
  updated_at    TIMESTAMP DEFAULT now()
);
```

---

## 🎯 Best Practices

### For Admins
1. ✅ Use consistent naming for merchant codes (city abbreviation + sequential number)
2. ✅ Use agent initials + sequential number for easy memorization
3. ✅ Generate strong PINs (avoid 1234, 0000, repeating patterns)
4. ✅ Provide credentials on paper (don't send via SMS/email)
5. ✅ Shred credential slips after conductor confirms successful pairing
6. ✅ Immediately unpair lost/stolen devices in web portal
7. ✅ Regularly audit active devices and agents
8. ✅ Train conductors on credential security

### For Conductors
1. ✅ Memorize merchant code, agent code, and PIN
2. ✅ Destroy credential slip after successful pairing
3. ✅ Never share PIN with anyone (not even admin)
4. ✅ Log out at end of shift (don't leave device logged in)
5. ✅ Report lost/stolen device immediately to admin
6. ✅ Don't write down credentials on device or visible location
7. ✅ Be aware of shoulder-surfing when entering PIN

### For Developers
1. ✅ Never log device tokens, access tokens, or PINs
2. ✅ Always hash PINs with bcrypt (never plain text)
3. ✅ Store device tokens in secure storage (flutter_secure_storage)
4. ✅ Validate pairing codes server-side (don't trust client)
5. ✅ Implement rate limiting on login attempts
6. ✅ Use HTTPS for all API communication
7. ✅ Implement token refresh mechanism
8. ✅ Clear all credentials on logout

---

## 📝 Example Complete Flow

### Scenario: New Conductor Setup

**Day 1: Admin Setup**
```
09:00 - Admin creates depot "Harare - Roadport" with merchant code HRE001
09:15 - Admin creates agent "Tinashe Moyo" with code TMO014, PIN 1234
09:30 - Admin registers device "HRE-DEV-003", system generates pairing code ABC234
09:35 - Admin prints credential slip and gives to Tinashe
```

**Day 1: Conductor Pairing**
```
10:00 - Tinashe receives POS terminal and credential slip
10:05 - Tinashe opens app, sees pairing screen
10:06 - Tinashe enters ABC234, clicks "Pair Device"
10:07 - App shows "Device paired successfully"
10:08 - App redirects to login screen
10:09 - Tinashe enters HRE001 (merchant), TMO014 (agent)
10:10 - Tinashe enters PIN 1234
10:11 - App shows "Welcome, Tinashe Moyo!" on home screen
10:12 - Tinashe shreds credential slip
```

**Day 2+: Daily Login**
```
06:00 - Tinashe arrives at depot
06:05 - Tinashe opens app (already paired)
06:06 - App shows login screen
06:07 - Tinashe enters HRE001, TMO014, 1234
06:08 - App shows home screen
06:09 - Tinashe starts issuing tickets
```

---

## ❓ FAQ

**Q: What if conductor forgets their PIN?**  
A: Admin must reset PIN in web portal. Conductor will receive new credentials.

**Q: Can one device be used by multiple conductors?**  
A: Yes! Multiple conductors can login/logout on same paired device. Each logs in with their own agent code + PIN.

**Q: What if pairing code is lost before pairing?**  
A: Admin must "unpair" device in portal to generate new pairing code, even though device was never paired.

**Q: Can merchant code or agent code be changed?**  
A: Not recommended. These are permanent identifiers. If needed, admin can create new agent record with new code.

**Q: What happens if device is stolen?**  
A: Admin immediately "unpairs" device in portal. This invalidates device token. Stolen device cannot login or issue tickets.

**Q: How long are access tokens valid?**  
A: Typically 1 hour. Refresh tokens are valid for 7 days. Configure in backend JWT settings.

**Q: Can conductor use same credentials on different devices?**  
A: No. Each device must be paired separately with its own device token. Agent can login on multiple devices, but each device needs its own pairing.

---

*Last Updated: March 2, 2026*  
*For questions or issues, contact the development team.*
