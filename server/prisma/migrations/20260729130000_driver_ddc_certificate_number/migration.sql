-- DDC certificate number on drivers
ALTER TABLE "tblDrivers" ADD COLUMN IF NOT EXISTS "defensive_driving_certificate_number" TEXT;
