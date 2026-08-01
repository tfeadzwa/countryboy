-- Mobile app release packages for Super Admin distribution
CREATE TABLE "tblAppReleases" (
    "id" TEXT NOT NULL,
    "version_name" TEXT NOT NULL,
    "version_code" INTEGER NOT NULL,
    "platform" TEXT NOT NULL DEFAULT 'android',
    "file_path" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "mime_type" TEXT,
    "release_notes" TEXT,
    "is_current" BOOLEAN NOT NULL DEFAULT false,
    "uploaded_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tblAppReleases_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "tblAppReleases_platform_version_name_version_code_key" ON "tblAppReleases"("platform", "version_name", "version_code");
CREATE INDEX "tblAppReleases_platform_is_current_idx" ON "tblAppReleases"("platform", "is_current");
CREATE INDEX "tblAppReleases_created_at_idx" ON "tblAppReleases"("created_at");
