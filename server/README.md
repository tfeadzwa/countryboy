# Countryboy Server

Express/TypeScript backend for the Countryboy bus ticketing system.

## Setup

1. Copy `.env.example` to `.env` and fill in `DATABASE_URL` and `JWT_SECRET`.
2. Install dependencies:
   ```sh
   cd server
   npm install
   ```
3. Generate Prisma client and run migrations:
   ```sh
   npm run prisma:generate
   npm run prisma:migrate
   npm run prisma:seed
   ```
4. Start development server:
   ```sh
   npm run dev
   ```

## Project structure
- `src/` – application code (controllers, services, middleware, routes, etc.)
- `prisma/` – Prisma schema and seed script

## Testing with Postman

### Super Admin Depot Context

When logged in as a **SUPER_ADMIN** (username: `super`), you must specify depot context for creating resources:

**Option 1: Header (Recommended)**
```
x-depot-id: <your-depot-id>
```

**Option 2: Query Parameter**
```
POST /agents?depot_id=<your-depot-id>
```

**Example Postman Setup:**
1. Login: `POST /auth/login` with `{"username": "super", "password": "password123"}`
2. Save the JWT token to environment variable: `{{jwt}}`
3. Create a depot: `POST /depots` (no depot context needed for this)
4. Save the depot ID: `{{depotId}}`
5. Add header to all subsequent requests:
   ```
   Authorization: Bearer {{jwt}}
   x-depot-id: {{depotId}}
   ```

See [postman-test-dummy-data.json](postman-test-dummy-data.json) for complete examples.

## Notes
- All database tables are prefixed with `tbl` as per specification.
- RBAC and depot scoping middleware are located under `src/middleware`.
- Super admins can manage multiple depots by changing the `x-depot-id` header.
- Authentication uses JWT tokens.
