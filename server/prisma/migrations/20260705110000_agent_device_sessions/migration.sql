-- Phase 1: last agent tracking on devices
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "last_agent_id" TEXT;
ALTER TABLE "tblDevices" ADD COLUMN IF NOT EXISTS "last_agent_login_at" TIMESTAMP(3);

ALTER TABLE "tblDevices"
  ADD CONSTRAINT "tblDevices_last_agent_id_fkey"
  FOREIGN KEY ("last_agent_id") REFERENCES "tblAgents"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Phase 2: agent ↔ device session history
CREATE TABLE IF NOT EXISTS "tblAgentDeviceSessions" (
  "id" TEXT NOT NULL,
  "depot_id" TEXT NOT NULL,
  "device_id" TEXT NOT NULL,
  "agent_id" TEXT NOT NULL,
  "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "ended_at" TIMESTAMP(3),
  "end_reason" TEXT,
  "app_version" TEXT,
  "login_type" TEXT NOT NULL DEFAULT 'online',
  CONSTRAINT "tblAgentDeviceSessions_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "tblAgentDeviceSessions"
  ADD CONSTRAINT "tblAgentDeviceSessions_depot_id_fkey"
  FOREIGN KEY ("depot_id") REFERENCES "tblDepots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tblAgentDeviceSessions"
  ADD CONSTRAINT "tblAgentDeviceSessions_device_id_fkey"
  FOREIGN KEY ("device_id") REFERENCES "tblDevices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tblAgentDeviceSessions"
  ADD CONSTRAINT "tblAgentDeviceSessions_agent_id_fkey"
  FOREIGN KEY ("agent_id") REFERENCES "tblAgents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "tblAgentDeviceSessions_device_id_ended_at_idx"
  ON "tblAgentDeviceSessions"("device_id", "ended_at");

CREATE INDEX IF NOT EXISTS "tblAgentDeviceSessions_agent_id_started_at_idx"
  ON "tblAgentDeviceSessions"("agent_id", "started_at");

CREATE INDEX IF NOT EXISTS "tblAgentDeviceSessions_depot_id_started_at_idx"
  ON "tblAgentDeviceSessions"("depot_id", "started_at");
