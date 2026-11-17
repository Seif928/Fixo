BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '15s';
DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['User','ClerkIdentityLink','PushDevice','OtpChallenge','RefreshToken','GeoLookupCache','GeoRequestGate','AdminMembership','AdminAuditLog','CoverageZone','CustomerAddress','ServiceCategory','ServiceSubSkill','ServiceOffering','AdminCatalogDraft','ProProfile','ProVerificationDocument','Booking','BookingStatusEvent','JobOffer','PaymentRecord','ChatMessage','Review','FavoriteService','FavoriteProfessional','Complaint','ProWeeklySchedule','ProLeave','SupportThread','SupportMessage','_ProCoverageZones','_ProSubSkills'] LOOP
    IF to_regclass(format('public.%I',tbl)) IS NULL THEN CONTINUE; END IF;
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',tbl);
    EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC',tbl);
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='anon') THEN EXECUTE format('REVOKE ALL ON public.%I FROM anon',tbl); END IF;
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN EXECUTE format('REVOKE ALL ON public.%I FROM authenticated',tbl); END IF;
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='fixo_backend') THEN
      EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO fixo_backend',tbl);
      EXECUTE format('DROP POLICY IF EXISTS fixo_backend_access ON public.%I',tbl);
      EXECUTE format('CREATE POLICY fixo_backend_access ON public.%I FOR ALL TO fixo_backend USING (true) WITH CHECK (true)',tbl);
    END IF;
  END LOOP;
  IF to_regprocedure('public.is_admin()') IS NOT NULL THEN
    REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon; END IF;
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE EXECUTE ON FUNCTION public.is_admin() FROM authenticated; END IF;
  END IF;
END $$;
COMMIT;
