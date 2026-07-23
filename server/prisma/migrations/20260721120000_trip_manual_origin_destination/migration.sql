-- Add conductor-entered corridor fields on trips.
ALTER TABLE "tblTrips" ADD COLUMN "origin" TEXT;
ALTER TABLE "tblTrips" ADD COLUMN "destination" TEXT;

-- Backfill from linked admin routes where available.
UPDATE "tblTrips" AS t
SET
  "origin" = r."origin",
  "destination" = r."destination"
FROM "tblRoutes" AS r
WHERE t."route_id" = r."id"
  AND (t."origin" IS NULL OR t."destination" IS NULL);

-- Fallback for orphan trips without a route.
UPDATE "tblTrips"
SET
  "origin" = COALESCE("origin", 'Unknown'),
  "destination" = COALESCE("destination", 'Unknown')
WHERE "origin" IS NULL OR "destination" IS NULL;

ALTER TABLE "tblTrips" ALTER COLUMN "origin" SET NOT NULL;
ALTER TABLE "tblTrips" ALTER COLUMN "destination" SET NOT NULL;

CREATE INDEX "tblTrips_depot_id_origin_destination_idx"
  ON "tblTrips"("depot_id", "origin", "destination");
