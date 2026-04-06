-- CreateTable
CREATE TABLE "tblRoles" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "tblRoles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblUserRoles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,

    CONSTRAINT "tblUserRoles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblDepots" (
    "id" TEXT NOT NULL,
    "merchant_code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "location" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblDepots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblAdminUsers" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "full_name" TEXT,
    "depot_id" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblAdminUsers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblAgents" (
    "id" TEXT NOT NULL,
    "full_name" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "agent_code" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblAgents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblDevices" (
    "id" TEXT NOT NULL,
    "serial_number" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "last_seen" TIMESTAMP(3),
    "app_version" TEXT,
    "sync_errors" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblDevices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblFleets" (
    "id" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblFleets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblRoutes" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblRoutes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblFares" (
    "id" TEXT NOT NULL,
    "route_id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "currency" TEXT NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblFares_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblTrips" (
    "id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "agent_id" TEXT NOT NULL,
    "device_id" TEXT,
    "fleet_id" TEXT NOT NULL,
    "route_id" TEXT NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL,
    "ended_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblTrips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblTickets" (
    "id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "trip_id" TEXT NOT NULL,
    "agent_id" TEXT NOT NULL,
    "device_id" TEXT,
    "serial_number" INTEGER,
    "ticket_type" TEXT NOT NULL,
    "currency" TEXT NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "linked_ticket_id" TEXT,
    "issued_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "voided" BOOLEAN NOT NULL DEFAULT false,
    "void_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,

    CONSTRAINT "tblTickets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblTicketVoids" (
    "id" TEXT NOT NULL,
    "ticket_id" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "agent_id" TEXT,
    "device_id" TEXT,

    CONSTRAINT "tblTicketVoids_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblSyncLogs" (
    "id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "device_id" TEXT,
    "agent_id" TEXT,
    "type" TEXT NOT NULL,
    "success" BOOLEAN NOT NULL DEFAULT true,
    "error" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tblSyncLogs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblSerialAllocations" (
    "id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "currency" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "last_number" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "tblSerialAllocations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tblDailyAggregates" (
    "id" TEXT NOT NULL,
    "depot_id" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "currency" TEXT NOT NULL,
    "revenue" DECIMAL(65,30) NOT NULL DEFAULT 0,
    "ticket_count" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "tblDailyAggregates_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tblRoles_name_key" ON "tblRoles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "tblUserRoles_userId_roleId_key" ON "tblUserRoles"("userId", "roleId");

-- CreateIndex
CREATE UNIQUE INDEX "tblDepots_merchant_code_key" ON "tblDepots"("merchant_code");

-- CreateIndex
CREATE UNIQUE INDEX "tblAdminUsers_username_key" ON "tblAdminUsers"("username");

-- CreateIndex
CREATE UNIQUE INDEX "tblAgents_username_key" ON "tblAgents"("username");

-- CreateIndex
CREATE UNIQUE INDEX "tblAgents_agent_code_key" ON "tblAgents"("agent_code");

-- CreateIndex
CREATE UNIQUE INDEX "tblDevices_serial_number_key" ON "tblDevices"("serial_number");

-- CreateIndex
CREATE UNIQUE INDEX "tblFleets_number_key" ON "tblFleets"("number");

-- CreateIndex
CREATE UNIQUE INDEX "tblSerialAllocations_depot_id_currency_date_key" ON "tblSerialAllocations"("depot_id", "currency", "date");

-- CreateIndex
CREATE UNIQUE INDEX "tblDailyAggregates_depot_id_date_currency_key" ON "tblDailyAggregates"("depot_id", "date", "currency");

-- AddForeignKey
ALTER TABLE "tblUserRoles" ADD CONSTRAINT "tblUserRoles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "tblAdminUsers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblUserRoles" ADD CONSTRAINT "tblUserRoles_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "tblRoles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblAdminUsers" ADD CONSTRAINT "tblAdminUsers_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblAgents" ADD CONSTRAINT "tblAgents_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblDevices" ADD CONSTRAINT "tblDevices_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblFleets" ADD CONSTRAINT "tblFleets_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblRoutes" ADD CONSTRAINT "tblRoutes_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblFares" ADD CONSTRAINT "tblFares_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "tblRoutes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblFares" ADD CONSTRAINT "tblFares_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "tblAgents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "tblDevices"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_fleet_id_fkey" FOREIGN KEY ("fleet_id") REFERENCES "tblFleets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTrips" ADD CONSTRAINT "tblTrips_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "tblRoutes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTickets" ADD CONSTRAINT "tblTickets_depot_id_fkey" FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTickets" ADD CONSTRAINT "tblTickets_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "tblTrips"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTickets" ADD CONSTRAINT "tblTickets_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "tblAgents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTickets" ADD CONSTRAINT "tblTickets_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "tblDevices"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tblTicketVoids" ADD CONSTRAINT "tblTicketVoids_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "tblTickets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
