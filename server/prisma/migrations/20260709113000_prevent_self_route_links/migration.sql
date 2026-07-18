-- Remove invalid self-referential links created before validation fixes.
DELETE FROM "tblRouteLinks"
WHERE "parent_route_id" = "child_route_id";

-- Enforce data integrity so a route can never be its own parent/child.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tblRouteLinks_parent_child_not_same'
  ) THEN
    ALTER TABLE "tblRouteLinks"
      ADD CONSTRAINT "tblRouteLinks_parent_child_not_same"
      CHECK ("parent_route_id" <> "child_route_id");
  END IF;
END $$;
