# Agent Credential Auto-Generation Implementation

## Overview
Implemented automatic generation of agent credentials (agent_code, username, and PIN) in the backend using PostgreSQL functions to ensure uniqueness and security.

## Changes Made

### 1. Database Layer (PostgreSQL Functions)

Created three PostgreSQL functions in migration file:
- **`generate_agent_code(full_name, depot_id)`**: Generates unique agent codes
  - Format: 3 uppercase letters + 3 digits (e.g., TMO014, JMO001)
  - Extracts initials from full name (first initial + first 2 letters of last name)
  - Finds next available number (001-999) within depot scope
  - Prevents duplicates within the same depot

- **`generate_username(full_name, depot_id)`**: Generates unique usernames
  - Format: lowercase first initial + lowercase last name (e.g., jmoyo, tndlovu)
  - Appends number if username exists (jmoyo2, jmoyo3, etc.)
  - Ensures uniqueness within depot scope

- **`generate_pin(depot_id)`**: Generates random 4-digit PINs
  - Format: 1000-9999 (4 digits)
  - Provides sufficient entropy for security

**Migration File**: `server/prisma/migrations/20260309_add_agent_generation_functions.sql`

**Run Migration**:
```bash
cd server
psql "postgresql://postgres:L0ck_$77@localhost:5432/countryboy" -f prisma/migrations/20260309_add_agent_generation_functions.sql
```

### 2. Backend Service Layer

**Updated**: `server/src/services/agentService.ts`

#### `createAgent()` function enhancements:
1. Auto-generates agent_code if not provided (using PostgreSQL function)
2. Auto-generates username if not provided (using PostgreSQL function)
3. Auto-generates PIN if not provided (using PostgreSQL function)
4. Hashes PIN with bcrypt before storing (security best practice)
5. Returns plain-text PIN in response for admin to share with agent
6. Includes merchant_code and depot_name in response

#### `listAgents()` function enhancements:
- Now includes depot information (merchant_code, depot_name) in response
- Uses Prisma's `include` to join depot table

### 3. Backend Validation Layer

**Updated**: `server/src/validators/schemas.ts`

#### `agentSchema` changes:
- Made `agent_code` optional (will be auto-generated if not provided)
- Kept validation rules for manual override capability
- Fields now marked as auto-generated in comments

**Updated**: `server/src/middleware/depotScope.ts`

#### Enhanced depot context handling:
- DEPOT_ADMIN: Automatically uses their assigned depot
- SUPER_ADMIN: Must provide depot context via:
  - User record depot_id (if assigned to specific depot)
  - `x-depot-id` request header
  - `depot_id` query parameter
- For POST/PUT/DELETE operations, depot context is **required** even for SUPER_ADMIN
- Clear error message: "Depot context required. Please specify depot via x-depot-id header or select a depot."

#### New middleware:
- Added `requireAnyRole(roleNames: string[])` middleware
- Allows multiple roles to access the same endpoint
- Used to allow both SUPER_ADMIN and DEPOT_ADMIN to manage agents

**Updated**: `server/src/routes/agent.ts`
- Changed POST /agents to use `requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN'])`
- Changed PUT /agents/:id to use `requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN'])`
- Fixes 403 Forbidden error for SUPER_ADMIN users

### 5. Frontend Service Layer

**Updated**: `frontend/src/lib/api/agent.service.ts`

#### Interface changes:
- `CreateAgentRequest`: Removed agent_code, username, pin (auto-generated)
- `UpdateAgentRequest`: Removed agent_code, username, pin (cannot be updated)
- Both interfaces now only include full_name and status

#### Method enhancements:
- `create()` now accepts optional `depotId` parameter
- Sends `x-depot-id` header for SUPER_ADMIN users
- DEPOT_ADMIN users don't need to provide depot (uses their assigned depot)

### 6. Frontend UI Layer

**Updated**: `frontend/src/components/AddAgentDialog.tsx`

#### Removed form fields:
- Username input field (auto-generated)
- Agent code input field (auto-generated)
- PIN input field (auto-generated)

#### Added features:
- **Depot selector for SUPER_ADMIN**: Dropdown to select which depot the agent belongs to
- Auto-loads depot list for SUPER_ADMIN users
- Auto-selects first depot if only one available
- Validation: SUPER_ADMIN must select a depot before creating agent

#### Simplified state management:
- Removed `username`, `agentCode`, and `pin` state variables
- Added `selectedDepotId` and `depots` state for SUPER_ADMIN
- Form now only captures `fullName`, `status`, and optionally `depotId` (for SUPER_ADMIN)
- Edit mode only allows updating full_name and status

#### Enhanced UX:
- Updated dialog description to inform admin that credentials are auto-generated
- Credentials dialog automatically shows after agent creation
- Plain-text credentials displayed for admin to copy and share

## API Changes

### POST /api/agents

**Before**:
```json
{
  "full_name": "John Moyo",
  "agent_code": "JMO014",
  "username": "jmoyo",
  "pin": "123456",
  "status": "ACTIVE"
}
```

**After**:
```json
{
  "full_name": "John Moyo",
  "status": "ACTIVE"
}
```

**Response** (enhanced):
```json
{
  "id": "uuid",
  "full_name": "John Moyo",
  "agent_code": "JMO001",
  "username": "jmoyo",
  "pin": "543219",
  "merchant_code": "HRE001",
  "depot_name": "Harare Central",
  "depot_id": "uuid",
  "status": "ACTIVE",
  "created_at": "2026-03-09T...",
  "updated_at": "2026-03-09T..."
}
```

**Note**: PIN is returned in plain-text ONLY on creation for admin to share. On subsequent GET requests, PIN is hashed.

### PUT /api/agents/:id

**Before**:
```json
{
  "full_name": "John Moyo Updated",
  "agent_code": "JMO015",
  "status": "INACTIVE"
}
```

**After** (simplified):
```json
{
  "full_name": "John Moyo Updated",
  "status": "INACTIVE"
}
```

**Note**: agent_code, username, and pin cannot be modified after creation.

## Security Enhancements

1. **PIN Generation in Database**: PostgreSQL generates PINs, reducing risk of predictable patterns
2. **Bcrypt Hashing**: PINs are hashed before storage using bcrypt (cost factor 10)
3. **One-time PIN Display**: Plain-text PIN only returned on creation, never on GET requests
4. **Uniqueness Guarantees**: Database functions ensure no duplicate agent_codes or usernames within depot
5. **Role-Based Access**: Both SUPER_ADMIN and DEPOT_ADMIN can manage agents

## Testing Instructions

### 1. Login as Admin
Use one of these accounts:
- **superadmin** / password123 (SUPER_ADMIN role - must select depot)
- **admin.harare** / password123 (DEPOT_ADMIN for HRE001 - auto-scoped)
- **admin.bulawayo** / password123 (DEPOT_ADMIN for BYO001)

### 2. Create Agent
1. Navigate to Agents page (/agents)
2. Click "Add Agent" button
3. **If SUPER_ADMIN**: Select a depot from dropdown (e.g., "Harare Central (HRE001)")
4. Enter:
   - Full Name: "Tatenda Sibanda"
   - Status: "ACTIVE" (default)
5. Click "Create Agent"

### 3. Verify Credentials
After creation, a credentials dialog should appear showing:
- Full Name: Tatenda Sibanda
- Username: tsibanda (auto-generated)
- Agent Code: TSI001 (auto-generated)
- PIN: 5432 (auto-generated, 4 digits)
- Merchant Code: HRE001 (from selected/assigned depot)
- Depot Name: Harare Central (from selected/assigned depot)

### 4. Copy Credentials
Use the copy buttons to copy username, agent code, and PIN to share with the agent.

### 5. Test Agent Login (Mobile)
Use the generated credentials in the mobile app:
- Merchant Code: HRE001
- Agent Code: TSI001
- PIN: 5432

### 6. Create Multiple Agents with Same Name
Create 2-3 agents with the same name (e.g., "John Moyo") to test:
- Agent codes increment: JMO001, JMO002, JMO003
- Usernames increment: jmoyo, jmoyo2, jmoyo3
- PINs are unique random 4-digit numbers

### 7. Test Edit Functionality
1. Click "Edit" on an existing agent
2. Verify you can only edit Full Name and Status
3. Agent code, username, and PIN are not shown (cannot be changed)

## Troubleshooting

### 403 Forbidden Error
**Fixed!** Both SUPER_ADMIN and DEPOT_ADMIN can now create agents.

### 400 Bad Request Error
**Cause**: SUPER_ADMIN users don't have a default depot assigned

**Solution**: 
1. Dialog now shows depot selector for SUPER_ADMIN
2. Select depot before creating agent
3. Backend receives depot via `x-depot-id` header

### Agent Code Duplicates
**Cause**: Migration not run or functions not created

**Solution**:
```bash
cd server
psql "postgresql://postgres:L0ck_$77@localhost:5432/countryboy" -f prisma/migrations/20260309_add_agent_generation_functions.sql
```

Verify functions exist:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'generate_%';
```

Should return:
- generate_agent_code
- generate_username
- generate_pin

### PIN Not Hashed in Database
**Cause**: Old agents created before this implementation

**Solution**: Existing agents' PINs are NOT affected. Only new agents get hashed PINs (4 digits). 
To update existing agents, you can run a migration script or manually:
```sql
-- Example: Update existing agent PINs (DO NOT run in production without backup)
-- UPDATE "tblAgents" SET pin = crypt('newpin', gen_salt('bf'));
```

## Database Schema Impact

No schema changes required. Existing columns are used:
- `agent_code` - Still VARCHAR, stores generated code
- `username` - Still VARCHAR, stores generated username
- `pin` - Still VARCHAR, stores bcrypt hash (60 chars)

## Migration Rollback

If you need to rollback these changes:

1. **Restore Previous Service**:
```sql
-- Drop the functions
DROP FUNCTION IF EXISTS generate_agent_code(TEXT, UUID);
DROP FUNCTION IF EXISTS generate_username(TEXT, UUID);
DROP FUNCTION IF EXISTS generate_pin(UUID);
```

2. **Revert Backend Code**:
```bash
git revert <commit-hash>
```

3. **Update Frontend**:
- Restore manual input fields in AddAgentDialog
- Update API interfaces to require agent_code

## Performance Considerations

- **Agent Code Generation**: O(n) where n = number of existing agents with same prefix
- **Username Generation**: O(n) where n = number of existing usernames
- **PIN Generation**: O(1) - random generation (4 digits: 1000-9999 = 9000 possibilities)
- **Impact**: Minimal - functions run only on agent creation (infrequent operation)
- **Optimization**: Functions include safety limits (999 iterations max) to prevent infinite loops

## Future Enhancements

1. **PIN Strength Requirements**: Add complexity requirements (currently 4 digits)
2. **PIN Rotation**: Implement periodic PIN change requirements
3. **Custom Prefixes**: Allow depots to define custom agent code prefixes
4. **Audit Trail**: Log all credential generation events
5. **Bulk Creation**: Add endpoint to create multiple agents at once
6. **Remember Depot Selection**: Store last selected depot for SUPER_ADMIN users

## Files Modified

### Backend
- `server/prisma/migrations/20260309_add_agent_generation_functions.sql` (NEW - updated for 4-digit PIN)
- `server/src/services/agentService.ts` (updated)
- `server/src/validators/schemas.ts` (updated)
- `server/src/middleware/rbac.ts` (updated - added requireAnyRole)
- `server/src/middleware/depotScope.ts` (NEW - enhanced depot context handling)
- `server/src/routes/agent.ts` (updated)

### Frontend
- `frontend/src/lib/api/agent.service.ts` (updated - accepts depotId parameter)
- `frontend/src/components/AddAgentDialog.tsx` (updated - depot selector for SUPER_ADMIN)

## Summary

✅ Agent credentials now auto-generated by backend
✅ PostgreSQL functions ensure uniqueness
✅ PINs are 4 digits (1000-9999) and securely hashed with bcrypt
✅ Frontend simplified (no manual input)
✅ Both SUPER_ADMIN and DEPOT_ADMIN can manage agents
✅ SUPER_ADMIN users select depot via dropdown
✅ DEPOT_ADMIN users auto-scoped to their depot
✅ Plain-text credentials shown once after creation
✅ Backwards compatible (manual override still possible via API)
✅ Fixed 400/403 errors with proper depot context handling

