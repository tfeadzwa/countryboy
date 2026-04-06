-- AlterTable
ALTER TABLE "tblSyncLogs" ADD COLUMN     "duration_ms" INTEGER,
ADD COLUMN     "records_pulled" INTEGER,
ADD COLUMN     "records_pushed" INTEGER;
