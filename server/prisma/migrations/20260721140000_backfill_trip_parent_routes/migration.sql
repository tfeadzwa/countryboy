-- Ensure historical trips get a main parent route from their origin/destination.
INSERT INTO "tblRoutes" (
  "id",
  "depot_id",
  "origin",
  "destination",
  "is_active",
  "created_at",
  "updated_at"
)
SELECT
  gen_random_uuid(),
  t."depot_id",
  t."origin",
  t."destination",
  true,
  NOW(),
  NOW()
FROM (
  SELECT DISTINCT "depot_id", "origin", "destination"
  FROM "tblTrips"
  WHERE "origin" IS NOT NULL
    AND "destination" IS NOT NULL
    AND TRIM("origin") <> ''
    AND TRIM("destination") <> ''
) AS t
ON CONFLICT ("depot_id", "origin", "destination") DO NOTHING;

UPDATE "tblTrips" AS trip
SET "route_id" = r."id"
FROM "tblRoutes" AS r
WHERE trip."route_id" IS NULL
  AND r."depot_id" = trip."depot_id"
  AND r."origin" = trip."origin"
  AND r."destination" = trip."destination";
