CREATE TYPE "AdminAccessRole" AS ENUM ('OWNER', 'ADMIN');
CREATE TABLE "AdminMembership" (
  slot INTEGER PRIMARY KEY, email TEXT NOT NULL UNIQUE, "userId" TEXT UNIQUE,
  role "AdminAccessRole" NOT NULL, "isActive" BOOLEAN NOT NULL DEFAULT true,
  "expiresAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminMembership_two_slots" CHECK ((slot=1 AND role='OWNER' AND "userId" IS NOT NULL) OR (slot=2 AND role='ADMIN')),
  CONSTRAINT "AdminMembership_user_fkey" FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE TABLE "AdminAuditLog" (
  id TEXT PRIMARY KEY, "actorUserId" TEXT, action TEXT NOT NULL, "entityId" TEXT NOT NULL,
  details JSONB NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AdminAuditLog_actor_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User"(id) ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "AdminAuditLog_createdAt_id_idx" ON "AdminAuditLog"("createdAt",id);
ALTER TABLE "AdminMembership" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "AdminAuditLog" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    REVOKE ALL ON "AdminMembership", "AdminAuditLog" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    REVOKE ALL ON "AdminMembership", "AdminAuditLog" FROM authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
    GRANT SELECT,INSERT,UPDATE,DELETE ON "AdminMembership", "AdminAuditLog" TO fixo_backend;
    CREATE POLICY fixo_backend_admin_membership ON "AdminMembership" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
    CREATE POLICY fixo_backend_admin_audit ON "AdminAuditLog" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
  END IF;
END $$;
