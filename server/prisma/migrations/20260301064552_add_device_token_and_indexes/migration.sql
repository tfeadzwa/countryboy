/*
  Warnings:

  - A unique constraint covering the columns `[token]` on the table `tblDevices` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "tblDevices" ADD COLUMN     "token" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "tblDevices_token_key" ON "tblDevices"("token");

-- CreateIndex
CREATE INDEX "tblTickets_depot_id_issued_at_idx" ON "tblTickets"("depot_id", "issued_at");

-- CreateIndex
CREATE INDEX "tblTickets_depot_id_agent_id_issued_at_idx" ON "tblTickets"("depot_id", "agent_id", "issued_at");
