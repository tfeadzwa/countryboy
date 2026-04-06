# Changelog

All notable changes to the Countryboy Backend API will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-01

### Breaking Changes - Schema v2 (Offline-First)

This release includes major schema improvements to better support offline-first mobile ticketing operations.

#### Routes API Changes
- **BREAKING**: `/routes` POST/PUT now requires `origin` and `destination` fields instead of single `name` field
  - Old: `{ "name": "Harare-Bulawayo" }`
  - New: `{ "origin": "Harare", "destination": "Bulawayo" }`
- Added depot-scoped uniqueness: same origin-destination pair cannot exist twice in a depot

#### Trips API Changes
- **BREAKING**: `route_id` is now **optional** in POST `/trips` (was required)
  - Supports trips started offline without route information
- Added `status` field to response (ACTIVE/ENDED) - use this instead of checking `ended_at` null
- Added `started_offline` boolean field to track offline trip origins

#### Tickets API Changes
- **BREAKING**: Field renamed: `ticket_type` → `ticket_category`
  - Old: `{ "ticket_type": "PASSENGER" }`
  - New: `{ "ticket_category": "PASSENGER" }`
- **BREAKING**: Field renamed: `linked_ticket_id` → `linked_passenger_ticket_id` (now a proper FK)
- **NEW**: Added `departure` field (optional string) for boarding location
- **NEW**: Added `destination` field (optional string) for drop-off location
- **NEW**: Added `issued_at` field (optional datetime) - defaults to server time if omitted
- **REMOVED**: `voided` and `void_reason` fields from ticket response
  - Void status now derived from `tblTicketVoids` events
  - Include `voids` relation in queries to check void status

#### Ticket Voids API Changes
- **BREAKING**: POST `/tickets/:id/void` now returns `tblTicketVoids` record instead of updated ticket
- **NEW**: Added optional `agent_id` and `device_id` fields to void request for audit trail
- Response includes `admin_user_id` (from JWT) and `created_at` timestamp

#### Passenger+Luggage Endpoint Changes
- **BREAKING**: Endpoint path changed: `/tickets/pair` → `/tickets/passenger-luggage`
- **BREAKING**: Request body no longer accepts `ticket_category` or `linked_passenger_ticket_id`
  - Service automatically creates both PASSENGER and LUGGAGE tickets with proper linking

#### Sync API Changes
- **BREAKING**: `trips` array in sync push must use optional `route_id` and include `status` + `started_offline`
- **BREAKING**: `tickets` array must use `ticket_category` instead of `ticket_type`
- **BREAKING**: `tickets` array should use `linked_passenger_ticket_id` for luggage linking
- Serial number allocation now uses device-based ranges (`tblSerialRanges`)
  - If `serial_number` is null and `device_id`/`currency` provided, server allocates from device ranges

### Added

#### Super Admin Depot Context Support
- **NEW**: Super admins can now specify depot context per request using:
  - Header: `x-depot-id: <depot-id>` (recommended)
  - Query param: `?depot_id=<depot-id>` (fallback)
- Priority order: `user.depot_id` → header → query param
- Enables super admins to manage multiple depots without switching accounts
- Applies to all depot-scoped endpoints: agents, devices, fleets, routes, fares, trips, tickets, sync

**Example:**
```http
POST /agents HTTP/1.1
Authorization: Bearer <jwt>
x-depot-id: abc-123-depot-id
Content-Type: application/json

{
  "full_name": "John Doe",
  "username": "john.doe",
  "agent_code": "AG-001"
}
```

### Database Schema Changes

#### Modified Tables
- **tblRoutes**: Replaced `name` with `origin` + `destination`; added `@@unique([depot_id, origin, destination])`
- **tblTrips**: Made `route_id` nullable; added `status` ENUM and `started_offline` boolean
- **tblTickets**: 
  - Renamed `ticket_type` → `ticket_category`
  - Renamed `linked_ticket_id` → `linked_passenger_ticket_id` with self-referencing FK
  - Added `departure`, `destination`, `issued_at` fields
  - Removed `voided` and `void_reason` fields
- **tblTicketVoids**: Added `admin_user_id` FK; proper FKs for `agent_id` and `device_id`
- **tblAgents**: Changed uniqueness from global to depot-scoped (`@@unique([depot_id, username])`, `@@unique([depot_id, agent_code])`)
- **tblFleets**: Changed uniqueness from global to depot-scoped (`@@unique([depot_id, number])`)
- **tblSyncLogs**: Added `depot_id` FK relation
- **tblDailyAggregates**: Added `depot_id` FK relation

#### New Tables
- **tblSerialRanges**: Replaced `tblSerialAllocations` for device-based serial number range allocation
  - Fields: `depot_id`, `device_id`, `currency`, `start_number`, `end_number`, `next_number`, `allocated_at`, `exhausted_at`

#### Removed Tables
- **tblSerialAllocations**: Removed in favor of `tblSerialRanges`

### Migration Notes

This is a **major version** release with breaking schema changes. To migrate:

1. **Database**: Run `npx prisma db push --force-reset` (development) or apply migration (production)
2. **API Clients**: Update all route creation/update calls to use `origin`/`destination`
3. **API Clients**: Update ticket creation calls to use `ticket_category` instead of `ticket_type`
4. **API Clients**: Add new optional fields (`departure`, `destination`, `issued_at`) to ticket payloads
5. **API Clients**: Update sync push payloads with new field names
6. **Mobile Apps**: Update offline storage to track trip `status` and `started_offline`
7. **Mobile Apps**: Implement device-based serial range allocation logic

### Documentation Updates
- Updated [PROJECT_DOCS.md](../../PROJECT_DOCS.md) with API reference for all changed endpoints
- Updated [ERD.md](ERD.md) with new schema diagram and design decisions log
- Updated [postman-test-dummy-data.json](postman-test-dummy-data.json) with v2 examples

---

## [1.0.0] - 2026-02-XX

Initial release with core ticketing functionality.

### Features
- JWT-based authentication with RBAC (SUPER_ADMIN, DEPOT_ADMIN)
- Depot management and multi-tenancy
- Agent, device, fleet, and route configuration
- Trip lifecycle management
- Ticket issuance and void operations
- Offline sync (push/pull)
- Basic metrics and reporting
- Comprehensive error handling with user-friendly messages
