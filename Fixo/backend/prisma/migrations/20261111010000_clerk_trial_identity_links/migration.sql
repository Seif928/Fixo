-- Staged Clerk trial only. No existing user, role, booking or provider field is modified.
CREATE TABLE "ClerkIdentityLink" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "issuer" TEXT NOT NULL,
  "subject" TEXT NOT NULL,
  "linkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ClerkIdentityLink_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ClerkIdentityLink_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "ClerkIdentityLink_issuer_subject_key" ON "ClerkIdentityLink"("issuer", "subject");
CREATE UNIQUE INDEX "ClerkIdentityLink_userId_issuer_key" ON "ClerkIdentityLink"("userId", "issuer");
ALTER TABLE "ClerkIdentityLink" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON "ClerkIdentityLink" FROM PUBLIC;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    REVOKE ALL ON "ClerkIdentityLink" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    REVOKE ALL ON "ClerkIdentityLink" FROM authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
    GRANT SELECT,INSERT,UPDATE,DELETE ON "ClerkIdentityLink" TO fixo_backend;
    CREATE POLICY fixo_backend_clerk_links ON "ClerkIdentityLink" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
  END IF;
END $$;
