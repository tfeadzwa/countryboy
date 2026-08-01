-- Defensive Driving Certificate (DDC) document fields on drivers
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "defensive_driving_certificate_file_path" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "defensive_driving_certificate_file_name" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "defensive_driving_certificate_expiry" TIMESTAMP(3);
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "defensive_driving_certificate_uploaded_at" TIMESTAMP(3);
