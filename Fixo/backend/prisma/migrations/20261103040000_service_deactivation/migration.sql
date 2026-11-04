-- AlterTable
ALTER TABLE "ServiceOffering" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "AdminCatalogDraft" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

