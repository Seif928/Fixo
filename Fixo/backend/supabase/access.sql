-- Idempotent Supabase Row-Level Security (RLS) & least-privilege grants for all
-- tables managed by Prisma in public schema. Denies PostgREST anon/authenticated access
-- and grants full table access exclusively to the backend service role (fixo_backend).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fixo_backend') THEN
    CREATE ROLE fixo_backend NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
END $$;

GRANT CONNECT ON DATABASE postgres TO fixo_backend;
GRANT USAGE ON SCHEMA public TO fixo_backend;

DO $$
DECLARE
  tbl text;
  tables text[] := ARRAY[
    'User',
    'ClerkIdentityLink',
    'PushDevice',
    'OtpChallenge',
    'RefreshToken',
    'GeoLookupCache',
    'GeoRequestGate',
    'AdminMembership',
    'AdminAuditLog',
    'CoverageZone',
    'CustomerAddress',
    'ServiceCategory',
    'ServiceSubSkill',
    'ServiceOffering',
    'AdminCatalogDraft',
    'ProProfile',
    'ProVerificationDocument',
    'Booking',
    'BookingStatusEvent',
    'JobOffer',
    'PaymentRecord',
    'ChatMessage',
    'Review',
    'FavoriteService',
    'FavoriteProfessional',
    'Complaint',
    'ProWeeklySchedule',
    'ProLeave',
    'SupportThread',
    'SupportMessage',
    '_ProCoverageZones',
    '_ProSubSkills'
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
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO fixo_backend', tbl);
    EXECUTE format('DROP POLICY IF EXISTS fixo_backend_access ON public.%I', tbl);
    EXECUTE format(
      'CREATE POLICY fixo_backend_access ON public.%I FOR ALL TO fixo_backend USING (true) WITH CHECK (true)',
      tbl
    );
  END LOOP;
END $$;
