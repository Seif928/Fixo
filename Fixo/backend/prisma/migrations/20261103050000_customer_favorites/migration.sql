CREATE TABLE IF NOT EXISTS "FavoriteService" (
  "id" TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "offeringId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "FavoriteService_user_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "FavoriteService_offering_fkey" FOREIGN KEY ("offeringId") REFERENCES "ServiceOffering"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "FavoriteService_userId_offeringId_key" ON "FavoriteService"("userId", "offeringId");
CREATE INDEX IF NOT EXISTS "FavoriteService_userId_createdAt_idx" ON "FavoriteService"("userId", "createdAt");

CREATE TABLE IF NOT EXISTS "FavoriteProfessional" (
  "id" TEXT PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "proProfileId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "FavoriteProfessional_user_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "FavoriteProfessional_pro_fkey" FOREIGN KEY ("proProfileId") REFERENCES "ProProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "FavoriteProfessional_userId_proProfileId_key" ON "FavoriteProfessional"("userId", "proProfileId");
CREATE INDEX IF NOT EXISTS "FavoriteProfessional_userId_createdAt_idx" ON "FavoriteProfessional"("userId", "createdAt");

ALTER TABLE "FavoriteService" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "FavoriteProfessional" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    REVOKE ALL ON "FavoriteService", "FavoriteProfessional" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    REVOKE ALL ON "FavoriteService", "FavoriteProfessional" FROM authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
    GRANT SELECT,INSERT,UPDATE,DELETE ON "FavoriteService", "FavoriteProfessional" TO fixo_backend;
    DROP POLICY IF EXISTS fixo_backend_favorite_service ON "FavoriteService";
    CREATE POLICY fixo_backend_favorite_service ON "FavoriteService" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
    DROP POLICY IF EXISTS fixo_backend_favorite_professional ON "FavoriteProfessional";
    CREATE POLICY fixo_backend_favorite_professional ON "FavoriteProfessional" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
  END IF;
END $$;
