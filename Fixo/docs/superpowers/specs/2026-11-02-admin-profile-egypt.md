# FIXO administration, real media and Egypt-wide location

User-approved scope: implement the dashboard now, review and repair the app, add optional profile-photo selection during first Google profile completion and photo replacement in Profile, show logout only in Profile, and let users choose every Egyptian governorate/address manually or explicitly request device location. All services must remain free. Single implementer; no Teamwork/subagents.

## Architecture and decisions

- Preserve verified Google -> name/phone/password -> Home and later phone/password login. Firebase Admin stays 13.10.0. Photos do not become an authentication requirement.
- Real device/file selection, image validation/resize and private Supabase Storage replace specimen generators in normal runtime. Existing User.avatarUrl can hold a private object reference. Authenticated backend proxies bytes; JWTs never appear in image URLs. Fixtures remain test-only. No real identity documents in tests.
- The admin is a separate responsive React/Vite web client in admin/, using the existing NestJS API. Owner and Admin are separate memberships, independent of the customer's/professional's application role. Owner is the verified Google account gamal6507@gmail.com. The friend's email is explicitly deferred; grant nobody else access until supplied or invited by Owner. Owner manages memberships; both manage operating records. Enforce access server-side and audit every write.
- Admin scope: overview, service/category/coverage editing, booking operations, customer/professional lookup and professional review, actual cash/earnings reports, editable content, audit history and owner-only membership management. Preserve historical booking price snapshots. Do not expose infrastructure secrets, rewrite paid records arbitrarily or invent transfer functionality.
- All 27 Egyptian governorates are selectable. A city/village/district and address may be entered for any location in Egypt; no comprehensive locality list is falsely claimed. Existing detailed coverage zones are preserved. Active professional availability remains based on actual records. Owner can manage coverage.
- Home location is a user choice, never an automatically preselected Sheikh Zayed address. Offer a visible location picker and an adjacent one-shot GPS action with contextual permission, denial/timeout fallback and manual correction. No background tracking. Use free maps and a configurable, cached/rate-limited reverse-geocoding provider with attribution.
- Logout appears in Profile only. Authentication account switching remains available when profile setup has not yet completed.

## Confirmed review findings to fix before acceptance

1. PrivateMediaPickerSheet fabricates one-pixel PNGs and simulates permission with a switch. It is not a real picker.
2. Booking uploads return a data URI; professional documents embed base64 in storageKey. HMAC metadata does not make a data URI expire or create private object storage.
3. ProService.advanceBookingStatus checks status/PIN attempts outside its transaction and updates by ID alone; concurrent retries can duplicate completion counts/events or race cancellation. Lock and recheck inside the transaction, persist failed attempts safely and make successful retries idempotent.
4. Home location controls cycle through zones and show fixed Cairo/Giza text; selection does not reliably drive the server-side professional feed.
5. Shared seed helpers must not write through ordinary read endpoints. Review professional verification mutations and authorization, document replacement/review races, uploads, role changes and cash settlement claims.

## Additional user steering
- Improve entrance, navigation and button motion using restrained finite animations; honor reduced-motion/accessibility settings. Preserve Stitch brand and touch targets, EN/AR and themes.
- Add a visible professional signup/sign-in entrance alongside customer entry. Persist intent across Google first setup. Use actual server dossier/approval to resume onboarding, review or approved dashboard. Selection grants no permissions, and the identity can still request customer services.

## Acceptance

Meaningful permission/ownership/concurrency tests, real picker cancel/denial tests, optional-photo registration/replacement tests, all-governorate selection/GPS fallback tests, admin owner-vs-admin access tests and real local customer/pro lifecycle checks. Use guarded localhost:5432/fixo_test only for DB tests, and port 3002 for E2E. Preserve port 3001. Normal Flutter tests stay offline; live checks opt in. Verify EN/AR, RTL/LTR, Light/Dark, 360/390/412dp at 1.35x, desktop, and actual browser behavior. iOS runtime/APNs requires a real supported environment; report unavailable checks honestly.

Deployment and Git are authorized to existing development services and task branches only; never enable billing or paid services. Keep secrets out of Git. New Storage credentials, if needed, are the last configuration step after implementation is reviewable. Do not declare a full live flow verified from mocked tests or health checks.
