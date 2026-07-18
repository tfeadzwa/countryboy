-- Replace single-parent hierarchy with many-to-many route links.
CREATE TABLE IF NOT EXISTS "tblRouteLinks" (
  "id" TEXT NOT NULL,
  "depot_id" TEXT NOT NULL,
  "parent_route_id" TEXT NOT NULL,
  "child_route_id" TEXT NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_by" TEXT,
  CONSTRAINT "tblRouteLinks_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "tblRouteLinks"
  ADD CONSTRAINT "tblRouteLinks_depot_id_fkey"
  FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tblRouteLinks"
  ADD CONSTRAINT "tblRouteLinks_parent_route_id_fkey"
  FOREIGN KEY ("parent_route_id") REFERENCES "tblRoutes"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "tblRouteLinks"
  ADD CONSTRAINT "tblRouteLinks_child_route_id_fkey"
  FOREIGN KEY ("child_route_id") REFERENCES "tblRoutes"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS "tblRouteLinks_parent_child_unique"
  ON "tblRouteLinks"("parent_route_id", "child_route_id");

CREATE INDEX IF NOT EXISTS "tblRouteLinks_depot_id_idx"
  ON "tblRouteLinks"("depot_id");

CREATE INDEX IF NOT EXISTS "tblRouteLinks_child_route_id_idx"
  ON "tblRouteLinks"("child_route_id");

-- Migrate existing single-parent relationships into the link table.
INSERT INTO "tblRouteLinks" ("id", "depot_id", "parent_route_id", "child_route_id", "created_at")
SELECT
  gen_random_uuid()::text,
  child."depot_id",
  child."parent_route_id",
  child."id",
  NOW()
FROM "tblRoutes" child
WHERE child."parent_route_id" IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE "tblRoutes" DROP CONSTRAINT IF EXISTS "tblRoutes_parent_route_id_fkey";
DROP INDEX IF EXISTS "tblRoutes_parent_route_id_idx";
ALTER TABLE "tblRoutes" DROP COLUMN IF EXISTS "parent_route_id";
