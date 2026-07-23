-- CreateTable
CREATE TABLE "tblDrivers" (
    "id" TEXT NOT NULL,
    "full_name" TEXT NOT NULL,
    "employee_code" TEXT,
    "phone" TEXT,
    "licence_number" TEXT,
    "depot_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblDrivers_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "tblTrips" ADD COLUMN "driver_id" TEXT;

-- CreateIndex
CREATE INDEX "tblDrivers_depot_id_status_idx" ON "tblDrivers"("depot_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "tblDrivers_depot_id_employee_code_key" ON "tblDrivers"("depot_id", "employee_code");

-- CreateIndex
CREATE INDEX "tblTrips_driver_id_idx" ON "tblTrips"("driver_id");

-- AddForeignKey
ALTER TABLE "tblDrivers" ADD CONSTRAINT "tblDrivers_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "tblDrivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;
