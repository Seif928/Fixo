-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "ComplaintCategory" AS ENUM ('SERVICE_QUALITY', 'BEHAVIOR', 'DELAY', 'OVERCHARGING', 'PROPERTY_DAMAGE', 'OTHER');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "ComplaintStatus" AS ENUM ('OPEN', 'IN_REVIEW', 'RESOLVED', 'REJECTED');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "Complaint" (
  "id" TEXT PRIMARY KEY,
  "bookingId" TEXT NOT NULL,
  "customerId" TEXT NOT NULL,
  "category" "ComplaintCategory" NOT NULL,
  "description" TEXT NOT NULL,
  "photoUrls" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  "status" "ComplaintStatus" NOT NULL DEFAULT 'OPEN',
  "adminNotes" TEXT,
  "resolvedAt" TIMESTAMP(3),
  "resolvedById" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Complaint_booking_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Complaint_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Complaint_resolvedBy_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "Complaint_customerId_createdAt_idx" ON "Complaint"("customerId", "createdAt");
CREATE INDEX IF NOT EXISTS "Complaint_bookingId_idx" ON "Complaint"("bookingId");
CREATE INDEX IF NOT EXISTS "Complaint_status_idx" ON "Complaint"("status");

ALTER TABLE "Complaint" ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
    REVOKE ALL ON "Complaint" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
    REVOKE ALL ON "Complaint" FROM authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
    GRANT SELECT,INSERT,UPDATE,DELETE ON "Complaint" TO fixo_backend;
    DROP POLICY IF EXISTS fixo_backend_complaint ON "Complaint";
    CREATE POLICY fixo_backend_complaint ON "Complaint" FOR ALL TO fixo_backend USING(true) WITH CHECK(true);
  END IF;
END $$;

