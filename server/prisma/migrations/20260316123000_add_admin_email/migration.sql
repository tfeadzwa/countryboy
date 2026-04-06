-- Add optional email to admin users for password reset
ALTER TABLE "tblAdminUsers"
ADD COLUMN "email" TEXT;

-- Ensure admin emails are unique when provided
CREATE UNIQUE INDEX "tblAdminUsers_email_key" ON "tblAdminUsers"("email");
