# Countryboy Backend ERD

This document visualizes the current database design from `prisma/schema.prisma` and highlights key relationship decisions. **Updated March 2026** to reflect offline-first schema improvements.

## ERD (Mermaid)

```mermaid
erDiagram
    tblRoles {
      string id PK
      string name
    }

    tblUserRoles {
      string id PK
      string userId FK
      string roleId FK
    }

    tblDepots {
      string id PK
      string merchant_code
      string name
      string location
    }

    tblAdminUsers {
      string id PK
      string username
      string password_hash
      string depot_id FK
      string status
    }

    tblAgents {
      string id PK
      string full_name
      string username
      string agent_code
      string depot_id FK
      string status
    }

    tblDevices {
      string id PK
      string serial_number
      string token
      string depot_id FK
      datetime last_seen
      string app_version
    }

    tblFleets {
      string id PK
      string number
      string depot_id FK
    }

    tblRoutes {
      string id PK
      string origin
      string destination
      string depot_id FK
    }

    tblFares {
      string id PK
      string route_id FK
      string depot_id FK
      string currency
      decimal amount
    }

    tblTrips {
      string id PK
      string depot_id FK
      string agent_id FK
      string device_id FK
      string fleet_id FK
      string route_id FK_nullable
      datetime started_at
      datetime ended_at
      string status
      bool started_offline
    }

    tblTickets {
      string id PK
      string depot_id FK
      string trip_id FK
      string agent_id FK
      string device_id FK
      int serial_number
      string ticket_category
      string currency
      decimal amount
      string departure
      string destination
      string linked_passenger_ticket_id FK_self
      datetime issued_at
    }

    tblTicketVoids {
      string id PK
      string ticket_id FK
      string reason
      string agent_id FK
      string device_id FK
      string admin_user_id FK
    }

    tblSyncLogs {
      string id PK
      string depot_id FK
      string device_id
      string agent_id
      string type
      bool success
    }

    tblSerialRanges {
      string id PK
      string depot_id FK
      string device_id FK
      string currency
      int start_number
      int end_number
      int next_number
      datetime allocated_at
      datetime exhausted_at
    }

    tblDailyAggregates {
      string id PK
      string depot_id FK
      date date
      string currency
      decimal revenue
      int ticket_count
    }

    tblAdminUsers ||--o{ tblUserRoles : has
    tblRoles ||--o{ tblUserRoles : assigned_to

    tblDepots ||--o{ tblAdminUsers : owns
    tblDepots ||--o{ tblAgents : has
    tblDepots ||--o{ tblDevices : has
    tblDepots ||--o{ tblFleets : has
    tblDepots ||--o{ tblRoutes : has
    tblDepots ||--o{ tblFares : has
    tblDepots ||--o{ tblTrips : has
    tblDepots ||--o{ tblTickets : has
    tblDepots ||--o{ tblSyncLogs : logs
    tblDepots ||--o{ tblSerialRanges : allocates
    tblDepots ||--o{ tblDailyAggregates : aggregates

    tblRoutes ||--o{ tblFares : priced_by
    tblRoutes ||--o{ tblTrips : route_optional

    tblAgents ||--o{ tblTrips : drives_sales
    tblAgents ||--o{ tblTickets : sold_by
    tblAgents ||--o{ tblTicketVoids : voided_by

    tblDevices ||--o{ tblTrips : records
    tblDevices ||--o{ tblTickets : sold_on
    tblDevices ||--o{ tblSerialRanges : assigned
    tblDevices ||--o{ tblTicketVoids : voided_on

    tblFleets ||--o{ tblTrips : vehicle

    tblTrips ||--o{ tblTickets : issues

    tblTickets ||--o{ tblTicketVoids : void_events
    tblTickets ||--o{ tblTickets : luggage_link

    tblAdminUsers ||--o{ tblTicketVoids : admin_voids
```

## Relationship Summary

- **RBAC** uses `tblRoles` and `tblUserRoles` (many-to-many between users and roles).
- **Depot-scoped operations**: Most entities (`tblAgents`, `tblDevices`, `tblFleets`, `tblRoutes`, `tblFares`, `tblTrips`, `tblTickets`) are scoped to depots.
- **Routes**: Defined by `origin` and `destination` pair with depot-scoped uniqueness (`@@unique([depot_id, origin, destination])`).
- **Trips**: Can optionally reference a route (`route_id` is nullable) to support offline trip starts. Track lifecycle via `status` (ACTIVE/ENDED) and `started_offline` flag.
- **Tickets**: 
  - Use `ticket_category` (PASSENGER/LUGGAGE) instead of generic `ticket_type`.
  - Include `departure`, `destination`, and `issued_at` for trip context.
  - `linked_passenger_ticket_id` is a self-referencing FK for luggage tickets.
  - Void status is derived from `tblTicketVoids` events, not stored as boolean flag.
- **Void tracking**: `tblTicketVoids` captures who voided a ticket (agent, device, or admin user) and when.
- **Serial allocation**: `tblSerialRanges` allocates serial number ranges per device and currency, supporting offline numbering with `start_number`, `end_number`, and `next_number`.

## Design Improvements Implemented (March 2026)

✅ **1. `linked_ticket_id` now a proper foreign key**
   - Renamed to `linked_passenger_ticket_id` with self-reference FK to `tblTickets(id)`.
   - Ensures referential integrity for luggage-passenger associations.

✅ **2. Analytics/support tables properly FK-linked**
   - `tblSyncLogs`, `tblSerialRanges`, `tblDailyAggregates` now have FK constraints to `tblDepots`.
   - `tblSerialRanges` FK-linked to `tblDevices`.
   - `tblTicketVoids` FK-linked to `tblAgents`, `tblDevices`, `tblAdminUsers`.

✅ **3. Depot-scoped uniqueness for operational entities**
   - `tblAgents`: `@@unique([depot_id, username])` and `@@unique([depot_id, agent_code])`.
   - `tblFleets`: `@@unique([depot_id, number])`.
   - `tblRoutes`: `@@unique([depot_id, origin, destination])`.

✅ **4. Route definitions improved**
   - Changed from single `name` field to `origin` + `destination` pair.
   - Prevents duplicate route definitions within a depot.

✅ **5. Void tracking via event model**
   - Removed `voided` and `void_reason` from `tblTickets`.
   - Ticket void status is now derived from presence of `tblTicketVoids` records.
   - Captures actor context (agent/device/admin) for audit trail.

## Additional Enhancements

- **Trip status tracking**: `status` field (ACTIVE/ENDED) replaces reliance on `ended_at` null checks.
- **Offline-first support**: `started_offline` flag on trips, nullable `route_id` for pre-sync trips.
- **Device-based serial ranges**: Replaces daily depot-wide allocation with per-device ranges for better offline operation.
- **Composite indexes**: Maintained on `tblTickets` for `[depot_id, issued_at]` and `[depot_id, agent_id, issued_at]` to support reporting queries.

## Design Decisions Log

### March 2026 Schema Evolution

**Context**: Refactored schema to better support offline-first mobile ticketing where conductors may operate without connectivity for extended periods.

**Key Decisions**:

1. **Routes structure** (origin/destination vs name)
   - **Decision**: Use separate `origin` and `destination` fields instead of single `name` field
   - **Rationale**: Provides structured data for route matching, enables better reporting by origin/destination, allows routes to be defined even when exact naming is inconsistent
   - **Alternative considered**: Keep single name field - rejected because it requires manual parsing and doesn't enforce structure

2. **Trip route association** (required vs optional)
   - **Decision**: Made `route_id` nullable on trips
   - **Rationale**: Trips started offline may not have route info immediately available; route can be assigned during sync
   - **Alternative considered**: Require route at trip start - rejected because it blocks offline operation when route data isn't synced

3. **Serial number allocation** (daily counter vs device ranges)
   - **Decision**: Use `tblSerialRanges` with per-device pre-allocated ranges (start/end/next)
   - **Rationale**: Devices can allocate serials offline without contention; each device gets a unique range per currency; range exhaustion is tracked
   - **Alternative considered**: Daily depot-wide counter - rejected because requires online coordination and causes conflicts

4. **Void tracking** (boolean flag vs event model)
   - **Decision**: Use `tblTicketVoids` event records as single source of truth, remove `voided`/`void_reason` from tickets
   - **Rationale**: Captures full audit context (who voided, when, which device/agent/admin); supports future void approval workflows; immutable audit trail
   - **Alternative considered**: Keep boolean flags - rejected because loses audit context and doesn't support approval/reversal flows

These decisions prioritize offline-first operation, data integrity, and auditability for cash-handling scenarios.
