-- Denormalized duty flags so start-trip pickers and APIs know who is busy.
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "on_trip" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "on_trip" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "tblFleets_on_trip_idx" ON "tblFleets"("on_trip");
CREATE INDEX IF NOT EXISTS "tblDrivers_on_trip_idx" ON "tblDrivers"("on_trip");

-- Backfill from currently active trips.
UPDATE "tblFleets" f
SET "on_trip" = true
WHERE EXISTS (
  SELECT 1 FROM "tblTrips" t
  WHERE t.fleet_id = f.id AND t.status = 'ACTIVE'
);

UPDATE "tblDrivers" d
SET "on_trip" = true
WHERE EXISTS (
  SELECT 1 FROM "tblTrips" t
  WHERE t.driver_id = d.id AND t.status = 'ACTIVE'
);
