ALTER TABLE "tblRoutes"
  ADD COLUMN IF NOT EXISTS "parent_route_id" TEXT;

ALTER TABLE "tblRoutes"
  ADD CONSTRAINT "tblRoutes_parent_route_id_fkey"
  FOREIGN KEY ("parent_route_id") REFERENCES "tblRoutes"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "tblRoutes_parent_route_id_idx"
  ON "tblRoutes"("parent_route_id");
