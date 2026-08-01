# Developer Role — Production Setup

How to ensure the `DEVELOPER` role exists in production and how to create or update a developer admin account.

**Do not run `prisma db seed` on production.** Seed scripts create test users and weak passwords.

---

## What the DEVELOPER role is

| | |
|---|---|
| **Privileges** | Inherits all `SUPER_ADMIN` privileges (see `server/src/middleware/rbac.ts`) |
| **Extra** | Can publish / promote / delete app releases (`requireRole('DEVELOPER')`) |
| **Visibility** | Developer accounts are hidden from super admins in Admin Users |
| **Depot** | Platform-level — `depot_id` is `NULL` |

The role row is inserted by migration:

`server/prisma/migrations/20260729090000_developer_role/migration.sql`

---

## Prerequisites

On the server:

```bash
cd /var/www/countryboy/server
npx prisma migrate deploy
```

Confirm the role exists:

```bash
sudo -u postgres psql -d countryboy -c \
  'SELECT id, name FROM "tblRoles" WHERE name = '\''DEVELOPER'\'';'
```

If the migration has not been applied yet (or you need to insert manually):

```bash
sudo -u postgres psql -d countryboy -c "
INSERT INTO \"tblRoles\" (id, name)
VALUES ('role-developer-001', 'DEVELOPER')
ON CONFLICT (name) DO NOTHING;
"
```

---

## Create a developer admin user

### 1. Generate a bcrypt password hash

From `/var/www/countryboy/server` (uses the project’s `bcryptjs`):

```bash
cd /var/www/countryboy/server
node -e "require('bcryptjs').hash('YOUR_STRONG_PASSWORD', 10).then(console.log)"
```

Copy the printed hash (starts with `$2b$10$...`).

### 2. Insert the user and assign the role

Replace placeholders before running:

- `YOUR_USERNAME`
- `YOUR_EMAIL`
- `$2b$10$PASTE_HASH_HERE`
- optional display name

```bash
sudo -u postgres psql -d countryboy <<'SQL'
INSERT INTO "tblAdminUsers" (
  id, username, email, password_hash, full_name, depot_id, status, created_at, updated_at
) VALUES (
  gen_random_uuid()::text,
  'YOUR_USERNAME',
  'YOUR_EMAIL',
  '$2b$10$PASTE_HASH_HERE',
  'Platform Developer',
  NULL,
  'ACTIVE',
  NOW(),
  NOW()
)
ON CONFLICT (username) DO NOTHING;

INSERT INTO "tblUserRoles" (id, "userId", "roleId")
SELECT gen_random_uuid()::text, u.id, r.id
FROM "tblAdminUsers" u
CROSS JOIN "tblRoles" r
WHERE u.username = 'YOUR_USERNAME'
  AND r.name = 'DEVELOPER'
ON CONFLICT ("userId", "roleId") DO NOTHING;
SQL
```

> If you paste a heredoc with `'SQL'`, the hash and username are taken literally. Edit the SQL first, or use an unquoted heredoc only if you understand shell expansion risks.

### 3. Verify

```bash
sudo -u postgres psql -d countryboy -c "
SELECT u.username, u.email, u.status, r.name AS role
FROM \"tblAdminUsers\" u
JOIN \"tblUserRoles\" ur ON ur.\"userId\" = u.id
JOIN \"tblRoles\" r ON r.id = ur.\"roleId\"
WHERE u.username = 'YOUR_USERNAME';
"
```

You should see one row with `role = DEVELOPER` and `status = ACTIVE`.

Log in at the admin UI (`https://countryboy.co.zw`) with that username and password.

---

## Fix username, email, or password

If the account was created with wrong details, update it in place (same user id and role mapping):

```bash
# Generate a new hash first (see step 1 above), then:
sudo -u postgres psql -d countryboy <<'SQL'
UPDATE "tblAdminUsers"
SET
  username = 'NEW_USERNAME',
  email = 'NEW_EMAIL',
  password_hash = '$2b$10$PASTE_NEW_HASH_HERE',
  full_name = 'Platform Developer',
  updated_at = NOW()
WHERE username = 'OLD_USERNAME';
SQL
```

If the role might be missing after a rename, re-run the `tblUserRoles` insert from the create section using `NEW_USERNAME`.

---

## Promote an existing admin to DEVELOPER

```bash
sudo -u postgres psql -d countryboy <<'SQL'
INSERT INTO "tblUserRoles" (id, "userId", "roleId")
SELECT gen_random_uuid()::text, u.id, r.id
FROM "tblAdminUsers" u
CROSS JOIN "tblRoles" r
WHERE u.username = 'EXISTING_USERNAME'
  AND r.name = 'DEVELOPER'
ON CONFLICT ("userId", "roleId") DO NOTHING;
SQL
```

---

## Security notes

- Prefer a long, unique password; never reuse seed/test passwords (`password123`, etc.).
- Do not commit real passwords or production hashes into the repo.
- Super admins cannot see or modify developer accounts from the Admin Users UI — only another developer can.
- After rotating a password, existing JWT sessions may remain valid until they expire; have the user sign in again with the new password.
- Keep developer accounts to a minimum (typically one or two platform operators).

---

## Related code

| Area | Path |
|------|------|
| RBAC / inheritance | `server/src/middleware/rbac.ts` |
| Admin users (hide developers) | `server/src/routes/adminUsers.ts` |
| App releases (developer-only publish) | `server/src/routes/appRelease.ts` |
| Role migration | `server/prisma/migrations/20260729090000_developer_role/` |
| Local seed (dev only) | `server/prisma/seed.ts` |
