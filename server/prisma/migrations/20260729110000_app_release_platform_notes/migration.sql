-- Split release changelogs into mobile app vs admin panel notes.
ALTER TABLE "tblAppReleases" ADD COLUMN IF NOT EXISTS "mobile_notes" TEXT;
ALTER TABLE "tblAppReleases" ADD COLUMN IF NOT EXISTS "admin_notes" TEXT;

-- Backfill legacy single release_notes into mobile_notes when empty.
UPDATE "tblAppReleases"
SET "mobile_notes" = "release_notes"
WHERE "mobile_notes" IS NULL
  AND "release_notes" IS NOT NULL
  AND btrim("release_notes") <> '';
