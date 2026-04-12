-- =============================================================================
-- Consolidation migration: brings production DB up to current schema.prisma
-- Applies all pending local changes in a single pass.
-- Safe to run on a fresh DB that already has the 5 prior migrations applied.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. tblAgents
--    - Make username nullable (was NOT NULL)
--    - Add pin column
--    - Replace global unique indexes with per-depot composite ones
-- ---------------------------------------------------------------------------
ALTER TABLE "tblAgents" ALTER COLUMN "username" DROP NOT NULL;
ALTER TABLE "tblAgents" ADD COLUMN IF NOT EXISTS "pin" TEXT;

-- Drop old global unique indexes
DROP INDEX IF EXISTS "tblAgents_username_key";
DROP INDEX IF EXISTS "tblAgents_agent_code_key";

-- New per-depot composite uniques
-- NULL usernames are ignored in unique checks (Postgres behaviour), so no partial index needed
CREATE UNIQUE INDEX IF NOT EXISTS "tblAgents_depot_id_username_key"    ON "tblAgents"("depot_id", "username");
CREATE UNIQUE INDEX IF NOT EXISTS "tblAgents_depot_id_agent_code_key"  ON "tblAgents"("depot_id", "agent_code");

-- ---------------------------------------------------------------------------
-- 2. tblDevices
--    - Add pairing_code, paired, paired_at, device_name, device_model
-- ---------------------------------------------------------------------------
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "pairing_code" TEXT;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "paired"       BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "paired_at"    TIMESTAMP(3);
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "device_name"  TEXT;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "device_model" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "tblDevices_pairing_code_key" ON "tblDevices"("pairing_code");

-- ---------------------------------------------------------------------------
-- 3. tblFleets
--    - Add status enum + capacity
--    - Replace global unique on number with per-depot composite unique
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE "FleetStatus" AS ENUM ('ACTIVE', 'MAINTENANCE', 'OUT_OF_SERVICE', 'RETIRED');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "status"   "FleetStatus" NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "capacity" INTEGER        NOT NULL DEFAULT 0;

DROP INDEX IF EXISTS "tblFleets_number_key";
CREATE UNIQUE INDEX IF NOT EXISTS "tblFleets_depot_id_number_key" ON "tblFleets"("depot_id", "number");

-- ---------------------------------------------------------------------------
-- 4. tblRoutes
--    - Replace single "name" column with origin + destination + is_active + distance_km
--    - Table is empty on production so rename/drop is safe
-- ---------------------------------------------------------------------------
ALTER TABLE "tblRoutes" ADD COLUMN IF NOT EXISTS "origin"      TEXT;
ALTER TABLE "tblRoutes" ADD COLUMN IF NOT EXISTS "destination" TEXT;
ALTER TABLE "tblRoutes" ADD COLUMN IF NOT EXISTS "is_active"   BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "tblRoutes" ADD COLUMN IF NOT EXISTS "distance_km" DECIMAL(65,30);

-- If there were existing rows they would need data – production has none.
-- Promote nullable origin/destination to NOT NULL.
-- (Wrapped in DO block so it's a no-op if columns already set NOT NULL.)
DO $$
BEGIN
  ALTER TABLE "tblRoutes" ALTER COLUMN "origin"      SET NOT NULL;
  ALTER TABLE "tblRoutes" ALTER COLUMN "destination" SET NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Drop the old "name" column that existed in the init migration.
ALTER TABLE "tblRoutes" DROP COLUMN IF EXISTS "name";

-- Per-depot composite unique
CREATE UNIQUE INDEX IF NOT EXISTS "tblRoutes_depot_id_origin_destination_key"
  ON "tblRoutes"("depot_id", "origin", "destination");

-- The init migration added a FK on route_id in tblTrips as NOT NULL + RESTRICT.
-- We need to make route_id nullable so trips can exist without a route.
-- First drop the old FK, alter the column, then re-add.
ALTER TABLE "tblTrips" DROP CONSTRAINT IF EXISTS "tblTrips_route_id_fkey";
ALTER TABLE "tblTrips" ALTER COLUMN "route_id" DROP NOT NULL;
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_route_id_fkey"
  FOREIGN KEY ("route_id") REFERENCES "tblRoutes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- 5. tblTrips
--    - Add status and started_offline columns
-- ---------------------------------------------------------------------------
ALTER TABLE "tblTrips" ADD COLUMN IF NOT EXISTS "status"          TEXT    NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE "tblTrips" ADD COLUMN IF NOT EXISTS "started_offline" BOOLEAN NOT NULL DEFAULT false;

-- ---------------------------------------------------------------------------
-- 6. tblTickets
--    - Rename ticket_type -> ticket_category
--    - Rename linked_ticket_id -> linked_passenger_ticket_id
--    - Add departure and destination columns
--    - Drop voided and void_reason (now tracked in tblTicketVoids)
-- ---------------------------------------------------------------------------

-- Rename columns (safe even if FK constraints exist; Postgres updates them automatically)
DO $$ BEGIN
  ALTER TABLE "tblTickets" RENAME COLUMN "ticket_type" TO "ticket_category";
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "tblTickets" RENAME COLUMN "linked_ticket_id" TO "linked_passenger_ticket_id";
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "departure"   TEXT;
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "destination" TEXT;

ALTER TABLE "tblTickets" DROP COLUMN IF EXISTS "voided";
ALTER TABLE "tblTickets" DROP COLUMN IF EXISTS "void_reason";

-- Self-referential FK for luggage linking (old constraint name was on linked_ticket_id;
-- drop by name if it exists, then re-add under the new column name)
ALTER TABLE "tblTickets" DROP CONSTRAINT IF EXISTS "tblTickets_linked_ticket_id_fkey";
ALTER TABLE "tblTickets" DROP CONSTRAINT IF EXISTS "tblTickets_linked_passenger_ticket_id_fkey";
ALTER TABLE "tblTickets" ADD CONSTRAINT "tblTickets_linked_passenger_ticket_id_fkey"
  FOREIGN KEY ("linked_passenger_ticket_id") REFERENCES "tblTickets"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- 7. tblTicketVoids
--    - Add admin_user_id with FK to tblAdminUsers
-- ---------------------------------------------------------------------------
ALTER TABLE "tblTicketVoids" ADD COLUMN IF NOT EXISTS "admin_user_id" TEXT;

ALTER TABLE "tblTicketVoids" DROP CONSTRAINT IF EXISTS "tblTicketVoids_admin_user_id_fkey";
ALTER TABLE "tblTicketVoids" ADD CONSTRAINT "tblTicketVoids_admin_user_id_fkey"
  FOREIGN KEY ("admin_user_id") REFERENCES "tblAdminUsers"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- 8. tblSerialAllocations -> tblSerialRanges
--    Drop old table (no FK references to it from other tables) and create new one.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS "tblSerialAllocations";

CREATE TABLE IF NOT EXISTS "tblSerialRanges" (
  "id"           TEXT        NOT NULL,
  "depot_id"     TEXT        NOT NULL,
  "device_id"    TEXT        NOT NULL,
  "currency"     TEXT        NOT NULL,
  "start_number" INTEGER     NOT NULL,
  "end_number"   INTEGER     NOT NULL,
  "next_number"  INTEGER     NOT NULL,
  "allocated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "exhausted_at" TIMESTAMP(3),
  "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "tblSerialRanges_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "tblSerialRanges_depot_id_device_id_currency_start_number_key"
  ON "tblSerialRanges"("depot_id", "device_id", "currency", "start_number");

ALTER TABLE "tblSerialRanges" DROP CONSTRAINT IF EXISTS "tblSerialRanges_depot_id_fkey";
ALTER TABLE "tblSerialRanges" ADD CONSTRAINT "tblSerialRanges_depot_id_fkey"
  FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tblSerialRanges" DROP CONSTRAINT IF EXISTS "tblSerialRanges_device_id_fkey";
ALTER TABLE "tblSerialRanges" ADD CONSTRAINT "tblSerialRanges_device_id_fkey"
  FOREIGN KEY ("device_id") REFERENCES "tblDevices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- 9. PostgreSQL helper functions for auto-generating agent credentials
--    (previously in the raw .sql file that prisma migrate ignored)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_agent_code(p_full_name TEXT, p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_prefix     TEXT;
  v_counter    INT := 1;
  v_agent_code TEXT;
  v_exists     BOOLEAN;
  v_names      TEXT[];
  v_first_name TEXT;
  v_last_name  TEXT;
BEGIN
  v_names := string_to_array(trim(p_full_name), ' ');

  IF array_length(v_names, 1) >= 2 THEN
    v_first_name := v_names[1];
    v_last_name  := v_names[array_length(v_names, 1)];
    v_prefix := upper(substring(v_first_name, 1, 1) || substring(v_last_name, 1, 2));
  ELSE
    v_prefix := upper(substring(p_full_name, 1, 3));
  END IF;

  WHILE length(v_prefix) < 3 LOOP
    v_prefix := v_prefix || 'X';
  END LOOP;
  v_prefix := substring(v_prefix, 1, 3);

  LOOP
    v_agent_code := v_prefix || lpad(v_counter::TEXT, 3, '0');

    SELECT EXISTS(
      SELECT 1 FROM "tblAgents"
      WHERE agent_code = v_agent_code
        AND depot_id   = p_depot_id
    ) INTO v_exists;

    EXIT WHEN NOT v_exists;
    v_counter := v_counter + 1;

    IF v_counter > 999 THEN
      RAISE EXCEPTION 'Unable to generate unique agent code for prefix %', v_prefix;
    END IF;
  END LOOP;

  RETURN v_agent_code;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_username(p_full_name TEXT, p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_username   TEXT;
  v_counter    INT := 1;
  v_exists     BOOLEAN;
  v_names      TEXT[];
  v_first_name TEXT;
  v_last_name  TEXT;
BEGIN
  v_names := string_to_array(trim(p_full_name), ' ');

  IF array_length(v_names, 1) >= 2 THEN
    v_first_name := v_names[1];
    v_last_name  := v_names[array_length(v_names, 1)];
    v_username   := lower(substring(v_first_name, 1, 1) || v_last_name);
  ELSE
    v_first_name := p_full_name;
    v_last_name  := p_full_name;
    v_username   := lower(p_full_name);
  END IF;

  LOOP
    IF v_counter = 1 THEN
      v_username := lower(substring(v_first_name, 1, 1) || v_last_name);
    ELSE
      v_username := lower(substring(v_first_name, 1, 1) || v_last_name) || v_counter::TEXT;
    END IF;

    SELECT EXISTS(
      SELECT 1 FROM "tblAgents"
      WHERE username  = v_username
        AND depot_id  = p_depot_id
    ) INTO v_exists;

    EXIT WHEN NOT v_exists;
    v_counter := v_counter + 1;

    IF v_counter > 999 THEN
      RAISE EXCEPTION 'Unable to generate unique username for %', p_full_name;
    END IF;
  END LOOP;

  RETURN v_username;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_pin(p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_pin TEXT;
BEGIN
  -- Returns a random 4-digit PIN; uniqueness enforcement is handled in application layer
  v_pin := lpad((1000 + floor(random() * 9000))::INT::TEXT, 4, '0');
  RETURN v_pin;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_agent_code(TEXT, TEXT) IS 'Generates unique agent code: 3 letters from name + 3 digits';
COMMENT ON FUNCTION generate_username(TEXT, TEXT)   IS 'Generates unique username: first initial + last name';
COMMENT ON FUNCTION generate_pin(TEXT)              IS 'Generates random 4-digit PIN';
