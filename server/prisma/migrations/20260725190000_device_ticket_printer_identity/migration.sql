-- Current Bluetooth printer on the conductor phone
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "printer_name" TEXT;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "printer_mac" TEXT;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "printer_serial" TEXT;

-- Snapshot of printer used when the ticket was printed
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "printer_name" TEXT;
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "printer_mac" TEXT;
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "printer_serial" TEXT;
