-- AlterTable
ALTER TABLE "tblAdminUsers" ADD COLUMN IF NOT EXISTS "phone" TEXT;

-- CreateTable
CREATE TABLE IF NOT EXISTS "tblSystemSettings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "company_name" TEXT NOT NULL DEFAULT 'CountryBoy',
    "company_email" TEXT,
    "company_phone" TEXT,
    "support_email" TEXT,
    "enabled_currencies" JSONB NOT NULL DEFAULT '["USD", "ZWL", "ZAR"]',
    "default_currency" TEXT NOT NULL DEFAULT 'USD',
    "timezone" TEXT NOT NULL DEFAULT 'Africa/Harare',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,

    CONSTRAINT "tblSystemSettings_pkey" PRIMARY KEY ("id")
);

-- Seed singleton row
INSERT INTO "tblSystemSettings" ("id", "company_name", "company_email", "enabled_currencies", "default_currency", "timezone", "created_at", "updated_at")
VALUES (
  'default',
  'CountryBoy',
  'bus@countryboy.co.zw',
  '["USD", "ZWL", "ZAR"]'::jsonb,
  'USD',
  'Africa/Harare',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
)
ON CONFLICT ("id") DO NOTHING;
