-- Add fleet compliance document expiry dates
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "licence_disc_expiry" TIMESTAMP(3);
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "cof_expiry" TIMESTAMP(3);
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "passenger_liability_expiry" TIMESTAMP(3);
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "route_authority_expiry" TIMESTAMP(3);
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "ppa_expiry" TIMESTAMP(3);
