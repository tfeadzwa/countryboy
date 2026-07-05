-- Add optional passenger contact fields to tickets (required at API layer for passenger categories)
ALTER TABLE "tblTickets" ADD COLUMN "passenger_name" TEXT;
ALTER TABLE "tblTickets" ADD COLUMN "passenger_phone" TEXT;
