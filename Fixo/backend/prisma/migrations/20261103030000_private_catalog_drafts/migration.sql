CREATE TABLE "AdminCatalogDraft" (
  id TEXT PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  "categorySlug" TEXT NOT NULL, "categoryNameEn" TEXT NOT NULL,
  "categoryNameAr" TEXT NOT NULL, "categoryIcon" TEXT NOT NULL,
  "titleEn" TEXT NOT NULL, "titleAr" TEXT NOT NULL,
  "descriptionEn" TEXT NOT NULL, "descriptionAr" TEXT NOT NULL,
  "baseInspectionEgp" INTEGER, "serviceFeeEgp" INTEGER, "estimatedDurationMins" INTEGER,
  version INTEGER NOT NULL DEFAULT 1, "publishedVersion" INTEGER,
  "offeringId" TEXT UNIQUE REFERENCES "ServiceOffering"(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminCatalogDraft_prices" CHECK (
    ("baseInspectionEgp" IS NULL OR "baseInspectionEgp" BETWEEN 0 AND 1000000) AND
    ("serviceFeeEgp" IS NULL OR "serviceFeeEgp" BETWEEN 0 AND 1000000) AND
    ("estimatedDurationMins" IS NULL OR "estimatedDurationMins" BETWEEN 5 AND 1440)),
  CONSTRAINT "AdminCatalogDraft_versions" CHECK (version > 0 AND
    (("publishedVersion" IS NULL AND "offeringId" IS NULL) OR
     ("publishedVersion" IS NOT NULL AND "publishedVersion" BETWEEN 1 AND version AND "offeringId" IS NOT NULL)))
);
CREATE INDEX "AdminCatalogDraft_categorySlug_slug_idx" ON "AdminCatalogDraft"("categorySlug",slug);
ALTER TABLE "AdminCatalogDraft" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    REVOKE ALL ON "AdminCatalogDraft" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    REVOKE ALL ON "AdminCatalogDraft" FROM authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
    GRANT SELECT,INSERT,UPDATE,DELETE ON "AdminCatalogDraft" TO fixo_backend;
    CREATE POLICY fixo_backend_catalog_drafts ON "AdminCatalogDraft" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
  END IF;
END $$;
