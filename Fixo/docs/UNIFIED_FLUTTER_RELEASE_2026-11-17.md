# Unified Flutter client and persistent sessions — 17 November 2026

## Approved decisions

The owner selected a single Flutter application for mobile, Web and administration, retaining the NestJS API. The separate Next.js client and its independent Supabase Auth flows were removed from the active tree; they remain available in Git history at 6115723. No accounts, bookings or profiles were deleted. Supabase-only accounts are not silently merged with Firebase identities.

## Changes

- Auth credentials stay in platform secure storage. SharedPreferences stores display profile/preferences only; legacy plaintext credential copies are removed after a successful restore. Preference-only legacy sessions can refresh and atomically populate an empty vault without losing the rotated token pair.
- Normal app/browser relaunch restores the existing account. Transient offline restore preserves a cached display session only when its identity and role match the unchanged secure-vault snapshot. Server-confirmed revocation and explicit logout clear it. Preferences alone never authenticate a user. Existing account-epoch/CAS safeguards are retained.
- Existing profile, professional assignments, bookings and administration now use the same Flutter repositories/API on Web and mobile. The retired Next.js service-key phone lookup and separate metadata-only profile writes are no longer deployed.
- /login, /register, /dashboard, /bookings and /profile route to the canonical Flutter screens with the same authentication gates. Original /onboarding, /auth/phone and /customer routes serve the Flutter entrypoint.
- Mutable asset URLs now revalidate rather than remaining immutable for a year. Camera policy allows the site's own requested camera flow. Default/release Firebase Hosting configurations reference the same tested build directory.
- CI uses independent generated test authentication secrets, removes the retired Next.js job and builds Flutter Web. The local QA runner stops on failed checks and requires an explicit isolated test database.
- Five backend fixture dates that had expired were replaced with relative future dates; application rejection of past bookings is unchanged.

## Supabase repair and approval

Live inspection found direct authenticated User INSERT/UPDATE privileges plus own-row policies and a SECURITY DEFINER is_admin function trusting User.role. This allowed bypassing the backend's role validation through the old direct-data access design. No live exploitation or other-user record reads were performed.

Migration 20261117010000_restore_backend_only_access was validated on local fixo_test inside a rolled-back transaction. Initial production execution was rejected by automatic approval review because it affected many tables. The owner then explicitly approved revoking anon/authenticated direct table access, retaining fixo_backend access and revoking public is_admin execution. The approved Supabase migration succeeded.

Post-change verification: 0 public tables accessible by anon/authenticated; fixo_backend User access preserved; anon/authenticated is_admin EXECUTE false. API readiness and public catalog requests remained successful. Pre-change ACL metadata is saved in security/SUPABASE_ACCESS_BEFORE_2026-11-17.json. No service keys or user records are in that snapshot. The older optional index-optimization migration has not been applied to the hosted database; it is separate from this access repair.

## Verification

- Flutter analyze: no issues.
- Flutter tests: 598 passed, 2 existing opt-in skips. New regressions failed before the session/route fixes and passed afterward.
- Backend lint and Nest build passed. Full backend tests after fixture correction: 61 suites / 570 tests passed against local fixo_test.
- New migration applied successfully to local fixo_test through Prisma migrate deploy.
- Release Web build and Android debug APK build passed. Android uses the existing ignored Firebase configuration for project fixo-home-services-6507, package eg.fixo.fixo_mobile.
- Web main.dart.js SHA256: FC2EAB2F71C89E20DBC21EA3E019253FA55930E807C33E79D61AC6D14DDBA447.
- APK SHA256: C98D238D418D850510E466C64FE567BA385043AE5B7DA31AEE0098BCBBC3FA1C.

## Rollout and actual login limits

- Vercel deployment dpl_BUWCyzUqFpu7yN5Q691GNorZGaHt is Ready at https://fixo-web-blue.vercel.app (deployment https://fixo-a1matuiez-gamal6507-3315.vercel.app). Project framework changed from nextjs to static/null.
- Firebase Hosting mirror https://fixo-home-services-6507.web.app was updated with the same build. API application source did not change; existing API deployment remains active.
- The owner reported an error when using Google after rollout but has not supplied the exact error text. Firebase public project configuration includes the stable FIXO domains; a CORS preflight to the API returned 204 with the correct allowed origin. No recent filtered firebase_identity_rejected events were available in the retained 30-minute log window. These checks do not prove the Google error is fixed.
- In actual Chrome, opening the login URL reached an already authenticated customer Home and the real Profile, demonstrating session recovery in that browser. A fresh sign-out/sign-in reproduction was not completed: browser focus changed to an unrelated page during the attempt and the user then stopped Computer Use with Escape. No further UI automation was performed afterward.
- Fresh Google login reproduction/error diagnosis, native-device restart proof and iOS runtime remain incomplete. Do not equate unit tests, a debug APK or an existing authenticated Chrome session with those checks. Apple provider activation, electronic payment merchant credentials and store signing remain external prerequisites; no billing or paid services were enabled.
