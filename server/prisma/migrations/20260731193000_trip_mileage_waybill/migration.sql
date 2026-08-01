-- AlterTable
ALTER TABLE "tblTrips" ADD COLUMN "starting_mileage" INTEGER;
ALTER TABLE "tblTrips" ADD COLUMN "waybill_no" TEXT;
ALTER TABLE "tblTrips" ADD COLUMN "closing_mileage" INTEGER;

-- CreateIndex
CREATE INDEX "tblTrips_depot_id_waybill_no_idx" ON "tblTrips"("depot_id", "waybill_no");
