-- Bound DDL lock wait inside migration transaction so active traffic is never stalled indefinitely.
SET LOCAL lock_timeout = '5s';

-- ============================================================================
-- 1. Drop superseded left-prefix indexes replaced by wider composite indexes
-- ============================================================================
DROP INDEX IF EXISTS "OtpChallenge_phone_idx";
DROP INDEX IF EXISTS "Booking_proProfileId_status_idx";
DROP INDEX IF EXISTS "Complaint_bookingId_idx";
DROP INDEX IF EXISTS "Complaint_status_idx";
DROP INDEX IF EXISTS "ProLeave_proProfileId_status_idx";
DROP INDEX IF EXISTS "SupportMessage_threadId_createdAt_idx";

-- ============================================================================
-- 2. Composite and sorted B-tree indexes aligned with Prisma schema
-- ============================================================================
CREATE INDEX IF NOT EXISTS "OtpChallenge_phone_createdAt_idx"
  ON "OtpChallenge"("phone", "createdAt" DESC);

CREATE INDEX IF NOT EXISTS "CoverageZone_isActive_nameEn_idx"
  ON "CoverageZone"("isActive", "nameEn");

CREATE INDEX IF NOT EXISTS "ServiceCategory_isActive_sortOrder_idx"
  ON "ServiceCategory"("isActive", "sortOrder");

CREATE INDEX IF NOT EXISTS "ServiceOffering_isActive_categoryId_idx"
  ON "ServiceOffering"("isActive", "categoryId");

CREATE INDEX IF NOT EXISTS "ProProfile_verificationStatus_idx"
  ON "ProProfile"("verificationStatus");

CREATE INDEX IF NOT EXISTS "ProProfile_verificationStatus_isOnline_primaryCategoryId_idx"
  ON "ProProfile"("verificationStatus", "isOnline", "primaryCategoryId");

CREATE INDEX IF NOT EXISTS "ProProfile_verificationStatus_updatedAt_id_idx"
  ON "ProProfile"("verificationStatus", "updatedAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "ProProfile_updatedAt_id_idx"
  ON "ProProfile"("updatedAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "ProVerificationDocument_proProfileId_docType_idx"
  ON "ProVerificationDocument"("proProfileId", "docType");

CREATE INDEX IF NOT EXISTS "Booking_customerId_createdAt_idx"
  ON "Booking"("customerId", "createdAt" DESC);

CREATE INDEX IF NOT EXISTS "Booking_proProfileId_status_scheduledDate_idx"
  ON "Booking"("proProfileId", "status", "scheduledDate");

CREATE INDEX IF NOT EXISTS "Booking_status_updatedAt_id_idx"
  ON "Booking"("status", "updatedAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "Booking_updatedAt_id_idx"
  ON "Booking"("updatedAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "BookingStatusEvent_bookingId_createdAt_id_idx"
  ON "BookingStatusEvent"("bookingId", "createdAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "BookingStatusEvent_createdAt_id_idx"
  ON "BookingStatusEvent"("createdAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "ChatMessage_bookingId_createdAt_id_idx"
  ON "ChatMessage"("bookingId", "createdAt" DESC, "id" DESC);

CREATE INDEX IF NOT EXISTS "Complaint_customerId_status_createdAt_idx"
  ON "Complaint"("customerId", "status", "createdAt" DESC);

CREATE INDEX IF NOT EXISTS "Complaint_bookingId_status_idx"
  ON "Complaint"("bookingId", "status");

CREATE INDEX IF NOT EXISTS "Complaint_status_createdAt_idx"
  ON "Complaint"("status", "createdAt" DESC);

CREATE INDEX IF NOT EXISTS "Complaint_createdAt_idx"
  ON "Complaint"("createdAt" DESC);

CREATE INDEX IF NOT EXISTS "ProLeave_proProfileId_status_startDate_idx"
  ON "ProLeave"("proProfileId", "status", "startDate" DESC);

CREATE INDEX IF NOT EXISTS "SupportThread_updatedAt_idx"
  ON "SupportThread"("updatedAt" DESC);

CREATE INDEX IF NOT EXISTS "SupportMessage_threadId_createdAt_id_idx"
  ON "SupportMessage"("threadId", "createdAt" DESC, "id" DESC);

-- ============================================================================
-- 3. PostgreSQL partial and functional indexes for hot selective paths
-- ============================================================================
CREATE INDEX IF NOT EXISTS "OtpChallenge_active_phone_created_idx"
  ON "OtpChallenge"("phone", "createdAt" DESC)
  WHERE "consumedAt" IS NULL;

CREATE INDEX IF NOT EXISTS "RefreshToken_active_user_idx"
  ON "RefreshToken"("userId")
  WHERE "revokedAt" IS NULL;

CREATE INDEX IF NOT EXISTS "ServiceOffering_active_category_idx"
  ON "ServiceOffering"("categoryId", "id")
  WHERE "isActive" = true;

CREATE INDEX IF NOT EXISTS "ProProfile_approved_online_dispatch_idx"
  ON "ProProfile"("primaryCategoryId", "updatedAt" DESC)
  WHERE "verificationStatus" = 'APPROVED' AND "isOnline" = true;

CREATE INDEX IF NOT EXISTS "Booking_unassigned_dispatch_idx"
  ON "Booking"("offeringId", "addressId", "scheduledDate")
  WHERE "proProfileId" IS NULL AND "status" IN ('PENDING_DISPATCH', 'OFFERED_TO_PRO');

CREATE INDEX IF NOT EXISTS "Booking_pro_completed_cairo_idx"
  ON "Booking"("proProfileId", COALESCE("completedAt", "updatedAt") DESC)
  WHERE "status" = 'COMPLETED';

CREATE INDEX IF NOT EXISTS "BookingStatusEvent_failed_pin_idx"
  ON "BookingStatusEvent"("bookingId")
  WHERE "note" = 'ARRIVAL_PIN_FAILED_ATTEMPT';

CREATE INDEX IF NOT EXISTS "ChatMessage_unread_booking_idx"
  ON "ChatMessage"("bookingId", "createdAt" DESC, "id" DESC)
  WHERE "readAt" IS NULL;

CREATE INDEX IF NOT EXISTS "ChatMessage_unread_feed_idx"
  ON "ChatMessage"("createdAt" DESC, "id" DESC)
  WHERE "readAt" IS NULL;

CREATE INDEX IF NOT EXISTS "ProLeave_approved_dates_idx"
  ON "ProLeave"("proProfileId", "startDate", "endDate")
  WHERE "status" = 'APPROVED';

CREATE INDEX IF NOT EXISTS "SupportThread_open_user_idx"
  ON "SupportThread"("userId", "updatedAt" DESC)
  WHERE "closed" = false;

-- ============================================================================
-- 4. Close RLS & privilege gaps on tables added without access policies
-- ============================================================================
DO $$
DECLARE
  tbl text;
  tables text[] := ARRAY[
    'PushDevice',
    'ProWeeklySchedule',
    'ProLeave',
    'SupportThread',
    'SupportMessage'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
    EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC', tbl);
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
      EXECUTE format('REVOKE ALL ON public.%I FROM anon', tbl);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
      EXECUTE format('REVOKE ALL ON public.%I FROM authenticated', tbl);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fixo_backend') THEN
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO fixo_backend', tbl);
      EXECUTE format('DROP POLICY IF EXISTS fixo_backend_access ON public.%I', tbl);
      EXECUTE format(
        'CREATE POLICY fixo_backend_access ON public.%I FOR ALL TO fixo_backend USING (true) WITH CHECK (true)',
        tbl
      );
    END IF;
  END LOOP;
END $$;

RESET lock_timeout;
