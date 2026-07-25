-- AlterTable
ALTER TABLE "tblFleets" ADD COLUMN IF NOT EXISTS "registration_number" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "tblFleets_depot_id_registration_number_key"
ON "tblFleets"("depot_id", "registration_number");
