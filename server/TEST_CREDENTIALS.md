# Test Credentials & Seed Data

## How to Use Seed Data

### Run the seed SQL file:
```bash
# From the server directory
psql -U your_username -d your_database -f prisma/seed-data.sql

# Or if using environment variable DATABASE_URL:
psql $DATABASE_URL -f prisma/seed-data.sql
```

### Or copy-paste into your database client:
- Open `prisma/seed-data.sql` in any text editor
- Copy all content
- Paste into your PostgreSQL client (pgAdmin, TablePlus, etc.)
- Execute

---

## 🔐 Admin Login Credentials

All admin accounts use the same password for easy testing:

| Username | Password | Role | Depot | Full Name |
|----------|----------|------|-------|-----------|
| `superadmin` | `password123` | SUPER_ADMIN | (All) | System Administrator |
| `admin.harare` | `password123` | DEPOT_ADMIN | HRE001 | John Moyo |
| `admin.bulawayo` | `password123` | DEPOT_ADMIN | BYO001 | Sarah Ncube |
| `admin.mutare` | `password123` | DEPOT_ADMIN | MUT001 | Grace Chikwamba |
| `manager.harare` | `password123` | MANAGER | HRE001 | Patrick Sibanda |
| `manager.bulawayo` | `password123` | MANAGER | BYO001 | Alice Dube |

---

## 📱 Mobile App - Agent Login

### Harare Agents (Depot: HRE001)

| Merchant Code | Agent Code | PIN | Full Name | Status |
|---------------|------------|-----|-----------|--------|
| `HRE001` | `TMO014` | `1234` | Tinashe Moyo | ACTIVE |
| `HRE001` | `FNC015` | `1234` | Farai Ncube | ACTIVE |
| `HRE001` | `RCH016` | `1234` | Rumbidzai Chuma | ACTIVE |
| `HRE001` | `TMA017` | `1234` | Tendai Mapfumo | INACTIVE |

### Bulawayo Agents (Depot: BYO001)

| Merchant Code | Agent Code | PIN | Full Name | Status |
|---------------|------------|-----|-----------|--------|
| `BYO001` | `NDU021` | `1234` | Nkululeko Dube | ACTIVE |
| `BYO001` | `TND022` | `1234` | Thandi Ndlovu | ACTIVE |
| `BYO001` | `SMO023` | `1234` | Siphosami Moyo | ACTIVE |

### Mutare Agents (Depot: MUT001)

| Merchant Code | Agent Code | PIN | Full Name | Status |
|---------------|------------|-----|-----------|--------|
| `MUT001` | `PMA031` | `1234` | Patience Marufu | ACTIVE |
| `MUT001` | `JCH032` | `1234` | James Chikwanha | ACTIVE |

---

## 📲 Device Pairing Codes

### Paired Devices (Already Active)
| Serial Number | Device Token | Depot | Last Seen |
|---------------|--------------|-------|-----------|
| `HRE-DEV-001` | `tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890` | HRE001 | 2 hours ago |
| `HRE-DEV-002` | `tok-b2c3d4e5-f6a7-4890-b2c3-d4e5f6a78901` | HRE001 | 1 hour ago |
| `BYO-DEV-001` | `tok-c3d4e5f6-a7b8-4901-c3d4-e5f6a7b89012` | BYO001 | 30 min ago |
| `BYO-DEV-002` | `tok-d4e5f6a7-b8c9-4012-d4e5-f6a7b8c90123` | BYO001 | 3 hours ago |
| `MUT-DEV-001` | `tok-e5f6a7b8-c9d0-4123-e5f6-a7b8c9d01234` | MUT001 | 4 hours ago |

### Unpaired Devices (For Testing Pairing Flow)
| Serial Number | Pairing Code | Depot | Status |
|---------------|--------------|-------|--------|
| `HRE-DEV-003` | `ABC234` | HRE001 | Not paired |
| `BYO-DEV-003` | `XYZ789` | BYO001 | Not paired |

**To test pairing:**
```bash
POST /api/devices/pair
{
  "pairing_code": "ABC234",
  "device_info": {
    "model": "Samsung Galaxy",
    "os_version": "Android 13"
  }
}
```

---

## 🚌 Sample Data Summary

### Depots (3 total)
- **HRE001** - Harare - Roadport
- **BYO001** - Bulawayo - Renkini  
- **MUT001** - Mutare - Sakubva

### Fleets (12 buses)
- Harare: HRE-101, HRE-102, HRE-103, HRE-104, HRE-105
- Bulawayo: BYO-201, BYO-202, BYO-203, BYO-204
- Mutare: MUT-301, MUT-302, MUT-303

### Routes (13 routes with fares)
**Harare:**
- Harare → Bulawayo ($15)
- Harare → Mutare ($12)
- Harare → Masvingo ($10)
- Harare → Gweru ($8)
- Harare → Chitungwiza ($2)

**Bulawayo:**
- Bulawayo → Harare ($15)
- Bulawayo → Victoria Falls ($20)
- Bulawayo → Gwanda ($7)
- Bulawayo → Plumtree ($5)

**Mutare:**
- Mutare → Harare ($12)
- Mutare → Chimanimani ($8)
- Mutare → Nyanga ($6)

### Trips (6 total)
- **3 completed trips** (with historical tickets)
- **3 active trips** (currently in progress)

### Tickets (15 issued)
- 12 PASSENGER tickets
- 3 LUGGAGE tickets (linked to passenger tickets)

---

## 🧪 Testing Scenarios

### 1. Super Admin Testing
**Login as:** `superadmin` / `password123`
- Can view all depots
- Must specify depot context via header: `x-depot-id: depot-hre-001`
- Or use query param: `?depot_id=depot-hre-001`

### 2. Depot Admin Testing
**Login as:** `admin.harare` / `password123`
- Automatically scoped to Harare depot (HRE001)
- Can manage agents, devices, fleets, routes for Harare only

### 3. Mobile Agent Login
**Test credentials:** 
- Merchant: `HRE001`
- Agent: `TMO014`
- PIN: `1234`

**API call:**
```bash
POST /api/agents/login
{
  "merchant_code": "HRE001",
  "agent_code": "TMO014",
  "pin": "1234"
}
```

### 4. Device Pairing
**Test with unpaired device:**
```bash
POST /api/devices/pair
{
  "pairing_code": "ABC234"
}
```
Returns long device token for API authentication.

### 5. Create Trip (Mobile)
**Headers:** `Authorization: Bearer tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890`
```bash
POST /api/trips
{
  "fleet_id": "fleet-hre-001",
  "route_id": "route-hre-001",
  "started_at": "2026-03-01T08:00:00Z"
}
```

### 6. Issue Ticket (Mobile)
```bash
POST /api/tickets
{
  "trip_id": "trip-004",
  "ticket_category": "PASSENGER",
  "currency": "USD",
  "amount": 15.00,
  "departure": "Harare",
  "destination": "Bulawayo",
  "issued_at": "2026-03-01T08:30:00Z"
}
```

---

## 📊 Database Statistics

After seeding, you should have:
- 4 Roles
- 3 Depots
- 6 Admin Users
- 9 Agents (7 ACTIVE, 1 INACTIVE, 1 SUSPENDED)
- 7 Devices (5 paired, 2 unpaired)
- 12 Fleet Vehicles
- 13 Routes
- 13 Fares
- 5 Serial Ranges
- 6 Trips (3 completed, 3 active)
- 15 Tickets
- 3 Daily Aggregates

---

## ⚠️ Security Notes

**FOR DEVELOPMENT ONLY!**

1. **Passwords:** All admin passwords are `password123` with a dummy bcrypt hash. Replace with real hashes in production!
2. **PINs:** All agent PINs are `1234` - hash these before production!
3. **Tokens:** Device tokens are simplified UUIDs - use proper token generation in production.
4. **Pairing Codes:** Sample codes are static - implement random generation in production.

---

## 🔄 Resetting Data

To clear all data and re-seed:
```sql
TRUNCATE TABLE "tblTickets", "tblTrips", "tblFares", "tblRoutes", "tblFleets", 
         "tblDevices", "tblAgents", "tblSerialRanges", "tblUserRoles", 
         "tblAdminUsers", "tblDepots", "tblRoles" CASCADE;
```

Then run the seed file again.

---

## 📱 Mobile App Quick Start

1. **First Time Setup (Device Pairing):**
   - Admin creates device in web portal
   - System generates pairing code (e.g., `ABC234`)
   - Conductor enters pairing code in mobile app
   - App receives and stores long device token

2. **Daily Login:**
   - Conductor enters: `HRE001` + `TMO014` + `1234`
   - App authenticates using stored device token
   - Conductor can now issue tickets

3. **Issue Tickets:**
   - Select route and fare
   - Issue passenger ticket (gets serial number from range)
   - Optionally issue luggage ticket (linked to passenger)
   - Tickets sync automatically when online

---

## 🌐 API Base URL

Development: `http://localhost:3000/api`

All endpoints documented in `postman-test-dummy-data.json`
