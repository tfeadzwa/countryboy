-- Driver compliance documents (licence scan + medical certificate)
ALTER TABLE "tblDrivers" ADD COLUMN "drivers_licence_file_path" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN "drivers_licence_file_name" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN "drivers_licence_expiry" TIMESTAMP(3);
ALTER TABLE "tblDrivers" ADD COLUMN "drivers_licence_uploaded_at" TIMESTAMP(3);
ALTER TABLE "tblDrivers" ADD COLUMN "medical_certificate_file_path" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN "medical_certificate_file_name" TEXT;
ALTER TABLE "tblDrivers" ADD COLUMN "medical_certificate_expiry" TIMESTAMP(3);
ALTER TABLE "tblDrivers" ADD COLUMN "medical_certificate_uploaded_at" TIMESTAMP(3);
