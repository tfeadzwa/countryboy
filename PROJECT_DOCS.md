# Countryboy Bus Ticketing System Documentation

This document describes the current state of the project and will be updated as new features are added. It is intended to serve as a living reference for developers working on the backend, frontend, and mobile components.

---

## 📁 Repository Structure

```
countryboy/
├── frontend/      # React admin application (mocked)
├── mobile/        # Flutter mobile app scaffold
└── server/        # Express + TypeScript backend
    ├── prisma/    # Prisma schema & seed script
    ├── src/
    │   ├── controllers/   # Express route handlers
    │   ├── middleware/    # Auth, RBAC and error handlers
    │   ├── routes/        # Route definitions
    │   ├── services/      # Business logic (sync, metrics, etc.)
    │   └── utils/         # Helpers (Prisma client, etc.)
    ├── package.json
    ├── tsconfig.json
    └── README.md        # Backend-specific instructions
``` 

> The `server` folder currently contains the working backend. Frontend and mobile subprojects are scaffolds with mock/UI-only content; they will be connected later.

---

## 🚀 Setup & Development

1. **Environment**: copy `.env.example` to `.env` and set `DATABASE_URL`, `JWT_SECRET`, and `PORT`.
2. Install dependencies:
   ```bash
   cd server
   npm install
   ```
3. Generate Prisma client and run migrations (requires a PostgreSQL instance):
   ```bash
   npm run prisma:generate
   npm run prisma:migrate
   npm run prisma:seed
   ```
4. Start the server in development mode:
   ```bash
   npm run dev
   ```

> The seed script creates the `SUPER_ADMIN` and `DEPOT_ADMIN` roles and a default super user (`username: super`, password `password123`).

---

## 📦 Dependencies & Versions

Key packages used in the backend:

- Node.js / TypeScript
- Express 4.18
- Prisma 7.4 (with PostgreSQL datasource)
- `jsonwebtoken`, `bcrypt` for auth
- `zod` for validation
- `winston` / `morgan` for logging
- Dev tools: ESLint, Jest, ts-node-dev

Prisma client is generated from `prisma/schema.prisma` and remains the single source of truth for the database schema.

---

## 🗄️ Database Schema (Prisma)

All tables use the `tbl` prefix as per specification. The schema includes:

- **Core tables**: `tblDepots`, `tblAdminUsers`, `tblAgents`, `tblDevices`, `tblFleets`, `tblRoutes`, `tblFares`, `tblTrips`, `tblTickets`
- **RBAC**: `tblRoles`, `tblUserRoles` (SUPER_ADMIN and DEPOT_ADMIN)
- **Analytics/support**: `tblTicketVoids`, `tblSyncLogs`, `tblSerialRanges`, `tblDailyAggregates`

Common fields: `depot_id`, `created_at`, `updated_at`, `created_by`, `updated_by`.

### Key Schema Features

- **Routes**: Use `origin` and `destination` instead of name, with depot-scoped uniqueness on the pair
- **Trips**: Support optional `route_id` for offline-started trips, track `status` (ACTIVE/ENDED) and `started_offline` flag
- **Tickets**: Include `ticket_category` (PASSENGER/LUGGAGE), `departure`, `destination`, and `issued_at` timestamp; `linked_passenger_ticket_id` is a self-referencing FK for luggage association
- **Void tracking**: Ticket voids are stored as events in `tblTicketVoids` with references to the voiding actor (agent/device/admin), not as boolean flags
- **Serial allocation**: `tblSerialRanges` tracks device-specific serial number ranges (start/end/next) for offline ticket numbering
- **Depot-scoped uniqueness**: Agents (username, agent_code) and fleets (number) enforce uniqueness within depot boundaries

Relationships and useful indexes have been defined to support filtering and reporting.

---

## 🛠️ Backend Architecture

### Middleware

- **authMiddleware**: verifies JWT, loads user with roles, attaches to `req.user`.
- **requireRole(roleName)**: ensures the caller has the specified role.
- **depotScopeMiddleware**: injects `req.depotId` from user record, or for super admins from `x-depot-id` header or `?depot_id` query param. Prevents cross-depot access for non-super admins.
- **errorHandler**: catches errors and returns JSON error responses.

### Services

- **syncService**: idempotent push/pull logic, upserting by UUID, serial number allocation, sync logging.
- **metricsService**: overview KPIs, revenue timeseries, and placeholders for further entity breakdowns.
- **agentService**: CRUD helpers for agent records with optional depot scoping.
- **deviceService**: similar helpers for device records.

### Controllers & Routes

- **Auth** (`/auth/login`): username/password login, returns JWT.
- **Depots** (`/depots`): creation (super only) and listing.
- **Agents** (`/agents`): list, create, update, fetch; scoped by depot and guarded by DEPOT_ADMIN for modifications.
- **Devices** (`/devices`): same pattern as agents.
- **Fleets** (`/fleets`): CRUD for fleet vehicles.
- **Routes** (`/routes`): CRUD for route definitions.
- **Fares** (`/fares`): CRUD for fare amounts tied to routes.
- **Trips** (`/trips`): start (`POST /trips`), end (`POST /trips/:id/end`), list active, view details, totals.
- **Tickets** (`/tickets`): issue, issue passenger+luggage pair, void, search by serial or ids.
- **Sync** (`/sync/push`, `/sync/pull`): offline sync endpoints with depot scoping.
- **Metrics** (`/admin/metrics/*`): overview and timeseries endpoints.

Routes are registered in `src/index.ts` with appropriate middleware.

### Utilities

- `src/utils/prisma.ts` exports a singleton Prisma client.

---

## 🔧 Current Functionality

The backend currently supports:

1. Authentication and role-based access control.
2. CRUD-style depot management (server only).
3. Configuration resources (agents, devices, fleets, routes, fares).
4. Core trip/ticket lifecycle and offline sync endpoints.
5. Simple metrics calculations for dashboard KPIs.

The system compiles cleanly and runs with `npm run dev`.

### 🧪 API Testing with Postman

You can exercise the API using Postman or any HTTP client. Below are a few example requests to get started:

1. **Login and obtain a JWT**
   - **Method:** POST
   - **URL:** `http://localhost:3000/auth/login`
   - **Body (JSON):**
     ```json
     { "username": "super", "password": "password123" }
     ```
   - **Response:**
     ```json
     {
       "token": "<JWT>",
       "user": { "id": "...", "username": "super", "roles": ["SUPER_ADMIN"], ... }
     }
     ```
   - In Postman, copy the `token` value and set it as an environment variable called `jwt`.
     You can use the "Tests" tab with the following script to automate this:
     ```js
     const json = pm.response.json();
     pm.environment.set("jwt", json.token);
     ```
   - The JWT is a base64‑encoded string containing the user ID and roles; it must be
     included in the `Authorization` header of subsequent requests.
   - You can also **manually generate** a token if you prefer not to call the login
     endpoint (for testing or scripting). Use the same `JWT_SECRET` from your
     `.env` file (`supersecretkey` by default). For example, run:
     ```bash
     node -e "const jwt=require('jsonwebtoken');console.log(jwt.sign({userId:'<id>',roles:['SUPER_ADMIN']},process.env.JWT_SECRET||'supersecretkey',{expiresIn:'8h'}));" \
       -r dotenv/config
     ```
     The command prints a JWT that you can copy into Postman or export as
     `export jwt=<token>` in your shell. Alternatively write a short script:
     ```js
     // gen-token.js
     import jwt from 'jsonwebtoken';
     import 'dotenv/config';
     console.log(
       jwt.sign({ userId: '<id>', roles: ['SUPER_ADMIN'] }, process.env.JWT_SECRET, { expiresIn: '8h' })
     );
     ```
     and run `node gen-token.js`. You may also use any online JWT generator
     (HS256, payload as shown, secret value) – the result is equivalent.

2. **Using the JWT for authenticated requests**
   - For each protected request (POST, GET, etc.), add a header:
     `Authorization: Bearer {{jwt}}`
   - Postman will automatically substitute the value from the environment variable.
   - Example:
     ```text
     GET http://localhost:3000/depots
     Authorization: Bearer {{jwt}}
     ```
   - If the token expires (8‑hour default), repeat the login step and update the
     `jwt` variable again.

2. **Create a Depot (SUPER_ADMIN only)**
   - **Method:** POST
   - **URL:** `http://localhost:3000/depots`
   - **Headers:** `Authorization: Bearer {{jwt}}`
   - **Body:** `{ "merchant_code": "HRE001", "name": "Harare Central Depot", "location": "Harare" }`
   - **Response:** created depot object with `id`.
   - **Important:** Save the returned depot `id` (e.g., store as `{{depotId}}` in Postman environment) for subsequent requests.
   - **Note:** Merchant code format is 6 chars: 3 uppercase letters + 3 digits (e.g., HRE001, BYO001)

> **📌 Note for SUPER_ADMIN users:**  
> When creating resources (agents, devices, fleets, routes, fares, etc.), you must specify which depot they belong to.  
> Add the depot context using **either**:
> - **Header (recommended):** `x-depot-id: {{depotId}}`
> - **Query param:** `?depot_id={{depotId}}`
>
> Example headers for creating an agent:
> ```
> Authorization: Bearer {{jwt}}
> Content-Type: application/json
> x-depot-id: abc-123-depot-id
> ```

3. **Create a Fleet**
   - **Method:** POST
   - **URL:** `http://localhost:3000/fleets`
   - **Headers:** 
     ```
     Authorization: Bearer {{jwt}}
     x-depot-id: {{depotId}}
     ```
   - **Body (JSON):** `{ "number": "FLEET-123" }`
   - **Notes:** Fleets belong to the specified depot context.

4. **Register a Device**
   - **Method:** POST
   - **URL:** `http://localhost:3000/devices`
   - **Headers:** 
     ```
     Authorization: Bearer {{jwt}}
     x-depot-id: {{depotId}}
     ```
   - **Body (JSON):** `{ "serial_number": "SN-XYZ-001" }`
   - **Response:** returns the device record including a secret `token` that
     must later be supplied by the mobile conductor app on sync requests.


5. **List Depots**
   - **Method:** GET
   - **URL:** `http://localhost:3000/depots`

### 💰 Testing Fare Endpoints in Postman (All `/fares` endpoints)

Use this section to test every fare route end-to-end.

#### Prerequisites

1. Login and set `{{jwt}}` as described above.
2. Ensure your token has `DEPOT_ADMIN` role (or `SUPER_ADMIN` with a valid depot context).
3. Create a route first (you need a valid `route_id` for fare creation):
   - **Method:** POST
   - **URL:** `http://localhost:3000/routes`
   - **Headers:** `Authorization: Bearer {{jwt}}`
   - **Body (JSON):**
     ```json
     { "origin": "Harare", "destination": "Bulawayo" }
     ```
   - Copy the returned route `id` and store it in a Postman variable, e.g. `{{routeId}}`.

#### 1) Create Fare — `POST /fares`

- **Method:** POST
- **URL:** `http://localhost:3000/fares`
- **Headers:**
  - `Authorization: Bearer {{jwt}}`
  - `Content-Type: application/json`
- **Body (JSON):**
  ```json
  {
    "route_id": "{{routeId}}",
    "currency": "USD",
    "amount": 10
  }
  ```
- **Expected Success:** `201 Created`
  ```json
  {
    "id": "<fare-id>",
    "route_id": "<route-id>",
    "currency": "USD",
    "amount": "10",
    "depot_id": "<depot-id>",
    "created_at": "...",
    "updated_at": "..."
  }
  ```

#### 2) List Fares — `GET /fares`

- **Method:** GET
- **URL:** `http://localhost:3000/fares`
- **Headers:** `Authorization: Bearer {{jwt}}`
- **Expected Success:** `200 OK` (array of fares in depot scope)
  ```json
  [
    {
      "id": "<fare-id>",
      "route_id": "<route-id>",
      "currency": "USD",
      "amount": "10"
    }
  ]
  ```

#### 3) Get Single Fare — `GET /fares/:id`

- **Method:** GET
- **URL:** `http://localhost:3000/fares/{{fareId}}`
- **Headers:** `Authorization: Bearer {{jwt}}`
- **Expected Success:** `200 OK`
- **Not found:** `404` with:
  ```json
  { "error": "Fare not found" }
  ```

#### 4) Update Fare — `PUT /fares/:id`

- **Method:** PUT
- **URL:** `http://localhost:3000/fares/{{fareId}}`
- **Headers:**
  - `Authorization: Bearer {{jwt}}`
  - `Content-Type: application/json`
- **Body (JSON):**
  ```json
  {
    "currency": "USD",
    "amount": 12
  }
  ```
- **Expected Success:** `200 OK` (updated fare record)

#### Common Error Examples for Fares

- **Invalid `route_id` on create** (foreign key):
  - **Status:** `400`
  - **Example:**
    ```json
    { "error": "Foreign key constraint failed on Route id" }
    ```

- **Missing/invalid token**:
  - **Status:** `401`
  - **Example:**
    ```json
    { "error": "Unauthorized" }
    ```

- **Insufficient role** (requires `DEPOT_ADMIN` for create/update):
  - **Status:** `403`
  - **Example:**
    ```json
    { "error": "Forbidden" }
    ```

#### Recommended Postman Variables

- `baseUrl` = `http://localhost:3000`
- `jwt` = token from login
- `routeId` = route id used by fares
- `fareId` = fare id returned after create

Then your URLs become:

- `{{baseUrl}}/fares`
- `{{baseUrl}}/fares/{{fareId}}`

---

## 📝 API Reference - Key Endpoints

### Routes (POST/PUT `/routes`)

**Request Body:**
```json
{
  "origin": "Harare",
  "destination": "Bulawayo"
}
```

**Notes:**
- Routes are now defined by origin-destination pairs instead of a single name field
- Depot-scoped uniqueness: same origin-destination pair cannot exist twice in the same depot
- Both fields are required

### Trips (POST `/trips`)

**Request Body:**
```json
{
  "agent_id": "uuid",
  "fleet_id": "uuid",
  "route_id": "uuid",           // OPTIONAL - can be omitted for offline trips
  "device_id": "uuid",           // optional
  "started_offline": false       // optional, defaults to false
}
```

**Response includes:**
```json
{
  "id": "uuid",
  "status": "ACTIVE",            // ACTIVE or ENDED
  "started_offline": false,
  "route_id": "uuid or null",
  "started_at": "2026-03-01T10:00:00Z",
  "ended_at": null,
  ...
}
```

**Notes:**
- `route_id` is now optional to support trips started while offline
- `status` field tracks lifecycle (ACTIVE/ENDED) instead of relying on `ended_at` null checks
- Use `POST /trips/:id/end` to mark a trip as ended

### Tickets (POST `/tickets`)

**Request Body:**
```json
{
  "trip_id": "uuid",
  "agent_id": "uuid",
  "device_id": "uuid",                    // optional
  "ticket_category": "PASSENGER",         // PASSENGER or LUGGAGE (not ticket_type)
  "currency": "USD",
  "amount": 10,
  "departure": "Harare",                  // optional - boarding location
  "destination": "Bulawayo",              // optional - drop-off location
  "issued_at": "2026-03-01T10:30:00Z",   // optional - defaults to now()
  "linked_passenger_ticket_id": "uuid"    // optional - for luggage tickets
}
```

**Response:**
```json
{
  "id": "uuid",
  "ticket_category": "PASSENGER",
  "departure": "Harare",
  "destination": "Bulawayo",
  "issued_at": "2026-03-01T10:30:00Z",
  "serial_number": 1001,
  ...
}
```

**Notes:**
- Field renamed: `ticket_type` → `ticket_category`
- New fields: `departure`, `destination`, `issued_at` for trip context
- `linked_passenger_ticket_id` is now a proper FK (was `linked_ticket_id`)
- Void status no longer included in ticket response - check `voids` relation or use separate endpoint

### Ticket Voids (POST `/tickets/:id/void`)

**Request Body:**
```json
{
  "reason": "Passenger cancelled",
  "agent_id": "uuid",      // optional - voiding agent
  "device_id": "uuid"      // optional - voiding device
}
```

**Response:** Returns the `tblTicketVoids` record (not the updated ticket)
```json
{
  "id": "uuid",
  "ticket_id": "uuid",
  "reason": "Passenger cancelled",
  "agent_id": "uuid or null",
  "device_id": "uuid or null",
  "admin_user_id": "uuid",   // populated from JWT
  "created_at": "2026-03-01T11:00:00Z"
}
```

**Notes:**
- Voiding now creates an event record instead of updating ticket's `voided` boolean
- Captures who performed the void (agent, device, or admin user) for audit trail
- To check if a ticket is voided, include `voids` relation in query or check for void records

### Passenger + Luggage Pair (POST `/tickets/passenger-luggage`)

**Request Body:** Same as single ticket but without `ticket_category` or `linked_passenger_ticket_id`
```json
{
  "trip_id": "uuid",
  "agent_id": "uuid",
  "device_id": "uuid",
  "currency": "USD",
  "amount": 10,
  "departure": "Harare",
  "destination": "Bulawayo",
  "issued_at": "2026-03-01T10:30:00Z"
}
```

**Response:**
```json
{
  "passenger": { "id": "uuid", "ticket_category": "PASSENGER", ... },
  "luggage": { "id": "uuid", "ticket_category": "LUGGAGE", "linked_passenger_ticket_id": "<passenger-id>", ... }
}
```

### Sync Push (POST `/sync/push`)

**Request Body:**
```json
{
  "trips": [ /* trip objects with all fields */ ],
  "tickets": [ /* ticket objects with ticket_category, departure, destination, issued_at, etc. */ ]
}
```

**Notes:**
- Serial number allocation now uses device-based ranges (`tblSerialRanges`)
- If ticket has no `serial_number` and includes `device_id` and `currency`, the service allocates from device's range
- Each device gets pre-allocated ranges (start/end/next) per currency

---

### 🧪 Automated Tests

A Jest-based test suite lives under `server/tests`. The test suite includes integration tests for depot creation, CRUD operations (agents, devices, fleets, routes), and fare endpoints. To run the tests:

```bash
cd server
npm install          # installs new dev deps (supertest)
npm test
```

Tests expect `DATABASE_URL` to point at a throwaway database since they will
truncate tables. You can set `TEST_SUPER_TOKEN` ahead of time or allow the
setup code to generate a token from the seeded super admin user.

---

### 💥 Improved Error Responses

To make client-side debugging easier, the API now translates common
Prisma errors into human-readable HTTP responses.  In addition to naming the
field that failed the constraint, the message also includes the actual value
that was supplied and the response may echo back the attempted payload so the
UI can re-populate the form.

Example when creating a depot with an existing merchant code:

```json
HTTP/1.1 409 Conflict
{
  "error": "Merchant code already exists: HRE001",
  "attempted": {
    "merchant_code": "HRE001",
    "location": "Harare"
  }
}
```

The formatter works for any table/column and simply converts snake-case names
like `merchant_code` to `Merchant code`.  Every controller that performs a
write operation now passes its request body (or relevant fields) to
`formatPrismaError` so the returned message will include the conflicting value.
The helper no longer returns the raw payload itself – that was deemed too noisy
and potentially sensitive.  Individual controllers still may choose to echo a
small `attempted` object of safe fields when they think the client needs it.
This behaviour has been applied across all route handlers including
trips, tickets, sync, configuration resources, etc., providing a consistent
error experience throughout the API.

### Supported Prisma error codes
In addition to unique constraint violations (`P2002`) the helper now
recognises a few other common codes:

* **P2003** – foreign key constraint failure.  The message will say
  "Foreign key constraint failed on <Field>: <value>" and return `400`.
* **P2025** – record not found when updating/deleting.  Translated to a
  `404` with the underlying message.

These are examples; you can extend `formatPrismaError` further if you
encounter other codes.  Controllers still perform manual `404` checks where
appropriate, but the helper provides a fallback for unexpected situations.

Both the controllers and the central error middleware use
the `formatPrismaError` helper so you will consistently see 409 responses with
friendly text instead of raw Prisma errors.

---
   - **Headers:** same auth header
   - **Response:** array of depots (scoped by role).

4. **Create an Agent (DEPOT_ADMIN)**
   - Swap to a depot‑scoped token (login with a DEPOT_ADMIN user).
   - **Method:** POST to `/agents` with appropriate body.

5. **Start a Trip & Issue Ticket**
   - POST `/trips` with `{ "agent_id": "...", "fleet_id": "...", "route_id": "..." }` (route_id is now optional for offline trips).
   - POST `/tickets` with `{ "trip_id": "...", "agent_id": "...", "ticket_category": "PASSENGER", "currency": "USD", "amount": 10, "departure": "Harare", "destination": "Bulawayo", "issued_at": "2026-03-01T10:00:00Z" }`.

6. **Search Tickets**
   - GET `/tickets/search?serial_number=12345` or other query parameters.

7. **Pull/Synchronize**
   - GET `/sync/pull?since=2026-02-28T00:00:00Z`
   - POST `/sync/push` with payload containing `trips` and `tickets` arrays.

> Tip: create a Postman collection with these requests and use environment variables (`{{jwt}}`, `{{depotId}}`, etc.) to streamline testing.

Document additional endpoints as you build them, following the same pattern.
---

## 🧪 Testing

A Jest configuration is included (`jest` and `ts-jest`), though no tests have been written yet. Adding unit and integration tests should be one of the next priorities.

---

## ✍️ How to Update Documentation

1. Edit this file (`PROJECT_DOCS.md`) with a new section or modify existing entries.
2. Commit the changes alongside the code that introduced the new feature.
3. Use descriptive headings (e.g., `## Features – Trip Lifecycle`) and keep the timeline order.

---

### ✅ Best practices currently implemented

Throughout the server we've incorporated a number of production-grade patterns:

- **Validation**: every request body, query and params are validated via Zod schemas at
  the boundary (`src/validators/schemas.ts`). Input is coerced where appropriate
  (`z.coerce.number()`), and invalid payloads generate structured validation errors.
- **Centralized error handling**: a single middleware returns JSON with `code`, `message`,
  `details`, and `requestId`. Stack traces are suppressed in production.
- **Request identifiers**: a UUID is generated per request and attached to responses
  (`X-Request-Id` header) and log entries for traceability.
- **Security headers and CORS**: `helmet` is enabled and CORS restricted via
  `CORS_ORIGINS` environment variable.
- **Rate limiting**: login endpoint is protected with `express-rate-limit` to
  thwart brute-force attempts.
- **Logging & observability**: Winston configured for JSON output in production,
  morgan integrates with structured logs. Logs include requestId, userId, depotId,
  duration, and other context. Sync operations log record counts and durations.
- **Device authentication**: sync endpoints require a per-device token header
  (`x-device-token`), devices are registered with unique secrets stored in
  `tblDevices.token` and locked to a depot.
- **Sync logging & support data**: `tblSyncLogs` stores push/pull events with
  `records_pushed`, `records_pulled` and `duration_ms` fields in addition to
  timestamps. This allows support teams to trace sync health and troubleshoot
  offline devices.
- **Transactions & atomicity**: critical operations (passenger+luggage issuance,
  serial allocation) run inside `prisma.$transaction` to ensure consistency.
- **Indexing**: ticket table has composite indexes to support common reporting
  filters by depot, agent and issued_at. Additional indexes can be added as load
  increases.
- **Database migrations**: schema migrations are managed via Prisma. A second
  migration added the device token field and relevant indexes.

These practices establish a robust foundation for handling cash transactions,
optimizing performance and easing production support. As features are added, the
project will follow the same architecture.

This document will grow as we implement the mobile app, the full admin UI, analytics alerts, and other system capabilities. Always reference it when new developers join or when revisiting architectural decisions.