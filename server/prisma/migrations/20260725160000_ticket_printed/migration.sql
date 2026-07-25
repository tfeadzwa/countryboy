-- Record successful thermal prints from the conductor app.
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "printed" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "tblTickets" ADD COLUMN IF NOT EXISTS "printed_at" TIMESTAMP(3);
