CREATE TABLE "GeoLookupCache" (
  "key" TEXT PRIMARY KEY,
  "result" JSONB NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "GeoRequestGate" (
  "key" TEXT PRIMARY KEY,
  "nextAllowedAt" TIMESTAMP(3) NOT NULL
);
CREATE INDEX "GeoLookupCache_expiresAt_idx" ON "GeoLookupCache" ("expiresAt");

ALTER TABLE "GeoLookupCache" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "GeoRequestGate" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON "GeoLookupCache", "GeoRequestGate" FROM PUBLIC;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON "GeoLookupCache", "GeoRequestGate" FROM anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fixo_backend') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON "GeoLookupCache", "GeoRequestGate" TO fixo_backend;
    CREATE POLICY fixo_backend_geo_cache ON "GeoLookupCache" TO fixo_backend USING (true) WITH CHECK (true);
    CREATE POLICY fixo_backend_geo_gate ON "GeoRequestGate" TO fixo_backend USING (true) WITH CHECK (true);
  END IF;
END $$;
