# FIXO connected services checkpoint — 2026-11-02

## Scope and cost constraints

Keep Firebase Spark, Supabase Free and Vercel Hobby. Do not enable billing, paid SMS, a paid trial, an Apple membership, or paid Maps APIs. Vercel Hobby is restricted to personal/non-commercial use: these are development/demo deployments, not approval to launch a commercial marketplace.

Demo Web: https://fixo-web-blue.vercel.app

API: https://fixo-api.vercel.app/api/v1

## Implemented server integrations

- Firebase verified email/Google identity exchange into existing FIXO JWT sessions. Email identities have no fabricated phone number. Existing accounts are never silently linked by email alone.
- Production SMS explicitly disabled. Development fixed OTP and in-memory persistence remain forbidden in production.
- Booking-participant chat, bounded message history, read receipts, real in-app activity, and notification preferences.
- FCM device registration/deletion scoped to authenticated users; bounded device counts, private generic notifications, invalid-token cleanup, and bounded provider requests. Sending occurs after successful chat persistence; failed delivery cannot roll it back.
- Supabase migrations added nullable User.phone, unique firebaseUid, and PushDevice. PushDevice has RLS; anon/authenticated/public access is revoked, and only the server role has CRUD access. Never run Prisma remote migrations over the Supabase-managed migration history.
- Firebase FCM v1 enabled. Dedicated sender identity has only the firebasecloudmessaging.admin role. The private credential is stored server-side in ignored local configuration and a sensitive Vercel variable. Never copy it into Flutter, Git, logs, or screenshots.
- Web Push public key generated with explicit user approval; configured in the API. No billing upgrade.

## Flutter integrations already implemented

- First registration uses verified Google identity followed by name, Egyptian phone alias and a Firebase password. Later login uses phone/password, with recovery through the linked email. The phone is an unverified username; it is not proof of phone ownership. No public phone-to-email lookup, no password storage in Prisma, no account merges by matching phone.
- One-time profile completion is JWT-protected and transactional; conflicting phone aliases and attempts to overwrite a complete profile are rejected.
- Secure token storage, server-verified session restoration, single-flight access-token refresh and local sign-out cleanup. A revoked refresh clears the session; provider outages preserve credentials. Requests from an old account are never replayed as a different signed-in account.
- Persisted language and theme preferences; native chat, profile/settings and in-app activity sheet.
- Customer lifecycle completion: Screen 06 (`order_tracking_page.dart`) live order milestone tracking with assigned artisan details and server-generated 4-digit arrival PIN; Screen 08 (`orders_page.dart`) real booking history with receipt preview; Screen 09 (`review_page.dart`) rate & review with duplicate protection and completed work photo upload; `booking_receipt_sheet.dart` official booking breakdown.
- Professional lifecycle completion: Screens 11–16 implemented end to end (`pro_signup_page.dart`, `pro_skills_page.dart`, `pro_verification_docs_page.dart`, `pro_verification_status_page.dart`, `pro_dashboard_page.dart`, `incoming_job_page.dart`). The current review corrected real response-contract mismatches in catalog options, profile/status/documents and dashboard earnings; constructor-only UI fixtures had missed these. Technician onboarding requires ID front/back and criminal-record photos and manual approval. Real private media integration is being verified; do not infer a live end-to-end technician journey from the UI tests.
- Media review: replaced the runtime specimen picker with real OS image selection. Profile photos and new technician document photos use bounded private Storage objects; avatar processing strips EXIF and resizes to256px. Credentials/live uploads are still pending. Existing booking/review data-URI uploads remain a separate migration task; an HMAC attached to a data URI does not make the bytes expire.
- Contextual device-push opt-in, denial/unavailable states, token refresh, sign-out unregister, foreground alerts and notification navigation.
- Embedded OpenFreeMap styles/tiles through MapLibre, with required OpenStreetMap/OpenMapTiles attribution. No key, account, billing or paid Maps API. A Cairo overview is not a selected address: the user explicitly picks a coordinate, and the existing address API persists it. No GPS permission, geocoding or live technician tracking is claimed. Public Google Maps links remain available for directions.
- Public Firebase Web service worker, with an explicit no-cache response header in the static deployment configuration.
- Android release INTERNET and notification permissions, Firebase config, debug signing fingerprints, Kotlin/R8 compatibility configuration; iOS minimum target 15 with Google sign-in callback configuration.
- Gemini's completed presentation changes integrated: EN/AR RTL, Light/Dark/System, bundled Manrope/Cairo fonts and licenses, readable real-font golden screenshots, professional app/Web icons and metadata, and responsive forms/cards.
- Customer bottom navigation opens the correct Home/Orders/Chat/Profile route, marks the selected tab accessibly, and preserves Home state while changing peer tabs. Screen 08 reads real bookings with status filters, pagination, retry and pull-to-refresh. Chat lists actual assigned booking conversations; it does not invent contacts.
- Removed the unsupported brand-certified promo badge and the claim of a 24/7 concierge; the same design area now explains the actual booking process. Onboarding no longer invents a technician count, arrival estimate, identity-review process or live tracking.

## Verification evidence and limits

- Backend lint/build passed and all 246 tests/27 suites passed, including real PostgreSQL tests for one-time profile setup, conflicts, device-registration races, customer lifecycle (tracking, receipts, reviews), and pro lifecycle (dossiers, atomic acceptance, arrival PIN verification, daily trajectory). Tests use only the guarded local fixo_test target.
- Flutter analyze passed with 0 issues, and 279 tests passed (2 explicit live checks skipped). All 16 screens (01–10 Customer, 11–16 Professional) verified across 360/390/412dp viewports at 1.35x text scale, Arabic RTL and English LTR, and Light/Dark themes. Logout also revokes the latest refresh token if push unregister triggered rotation.
- Integrated release Web build passed (`flutter build web --release`). Web contains the fonts and FCM service worker. Android release build passed. Signing is still the development/debug key, not a Play Store release setup.
- Deployed API readiness and live catalog reads returned HTTP 200 with PostgreSQL persistence. Public OTP request returned HTTP 503, as intended.
- FCM service-account validation reached the live FCM v1 API and returned INVALID_ARGUMENT for a deliberately invalid, validation-only token. This verifies API authorization, not delivery to an actual device.
- User approved real Google sign-in and browser notification testing with the configured Google account. The user confirmed that real Google sign-in now works after the CommonJS fix. Actual device notification delivery has not yet been verified.
- The deployed Web login rendered correctly in the real browser and opened Google's account chooser. Browser control stalled while selecting the authorized account; the user must complete that step and enter the new password in the app. That earlier browser limitation is historical: the user subsequently confirmed login works. It remains no proof of notification delivery.

## Remaining live verification

The user confirmed Google login works. New media uploads, professional onboarding/approval, notification delivery, national coverage and administration still need their specific runtime checks. User approval for Google identity sharing and browser notifications is already recorded. Creating the new password must be completed by the user in the app; never ask for it in chat or choose one on the user's behalf. Do not create cloud bookings/payments for this account test.

iOS runtime/APNs remains unavailable without appropriate Apple credentials and a macOS/Xcode test environment. Do not claim it works. SMS remains disabled. No real professionals/dispatch/tracking/reviews have been fabricated; missing product workflows remain separate development work.

## Reproduction

Configure server variables from backend/.env.example with independent secrets. Local integration tests must target explicit localhost:5432/fixo_test and pass the existing fail-closed guard. Native Firebase configuration files are deliberately ignored: regenerate them with FlutterFire against the approved project. Public Firebase client options and the Web service worker contain no service-account secret.

Build Web using `flutter build web --release --dart-define=FIXO_API_BASE_URL=https://fixo-api.vercel.app/api/v1`. Copy `mobile/vercel.static.json` to `mobile/build/web/vercel.json` and the locally linked `.vercel/project.json` into `build/web/.vercel/project.json`, then run `vercel deploy --prod --yes` from `build/web`. Deploying source mobile/ as a guessed framework is not the static-artifact deployment used here.

Brand icons reuse the existing Material `handyman_rounded` glyph from FixoBrandMark. Re-export with `python tool/generate_brand_icons.py <Flutter SDK>/bin/cache/artifacts/material_fonts/materialicons-regular.otf` (Pillow required). The font is supplied/licensed by the Flutter SDK; no new remote logo service is used.

## Google sign-in on Vercel: runtime compatibility fix

The reported cloud-only Google failure reached `/auth/firebase/session` but was rejected before first-profile setup. Safe server diagnostics confirmed matching Firebase audience/issuer and `ERR_REQUIRE_ESM`. The actual Firebase Admin 14 -> jwks-rsa 4 -> jose 6 dependency chain failed under the CommonJS loader; a real-SDK subprocess test reproduced the same failure with `--no-experimental-require-module`. See the [upstream Firebase issue](https://github.com/firebase/firebase-admin-node/issues/3181).

Firebase Admin is deliberately pinned to the official 13.10.0 release, whose dependency chain supports this loader. Keep this pin until a newer version passes `firebase-runtime.spec.ts` and the cloud sign-in check. Signature, issuer, audience and expiry verification still use the SDK's `verifyIdToken`; no unsigned token, emulator or fabricated identity fallback was added. Diagnostics record only safe error codes and match booleans, never tokens, provider messages, email or user IDs.

Client errors now distinguish a rejected Google/session exchange from an incorrect phone/password and distinguish Google account conflicts from phone conflicts. The intended flow remains Google -> name/phone/password once -> Home; later login uses phone/password without SMS.

Post-fix validation: backend lint/build and 230 tests/25 suites passed; Flutter analyze and 272 tests passed with 2 opt-in live suites skipped; the integrated Web build passed. Gemini's visual QA commit is 2082e65 and remains preserved. The user has since confirmed Google sign-in works; device notification delivery remains unverified. Existing npm audit findings in the Nest/Multer/Prisma dependency chains are outside this targeted Firebase compatibility fix; Firebase is not among the reported high-severity dependencies.

## Current review branch (2026-11-02)

- Branch fixo-admin-profile in an isolated worktree preserves the original Gemini branch. Commit a61013a was pushed: atomic professional transitions/PIN attempts, separate public technician entry, finite accessible motion, Profile-only logout and corrected /pro/me parsing. Full evidence for that commit:246backend tests and294Flutter tests (+2opt-in skips), analyze clean.
- Uncommitted media/pro fixes add optional signup photo and Profile replacement, real image_picker1.2.3, authenticated private bytes, explicit2MB multipart limit, no shared image caching, reviewer/identity locks and all3required documents before approval. Local backend suite:260/260 tests in30suites, including multipart boundaries and real guarded PostgreSQL workflows. Flutter functional tests pass; two Profile goldens need updating for the intentional real-photo control. Never claim these changes are deployed yet.
- Supabase fixo-private bucket exists, public=false, max object2MB, no public object policies. Server Storage credential is not configured yet. Never recover secrets through SQL or ship them in a client.
- FirebaseAdmin remains pinned13.10.0. Multer2.5 override fixes the prior upload advisory. npm still reports Prisma/config/deepmerge high advisories and moderate transitive findings; do not label the dependency audit clean.
- All27governorates/GPS and protected Owner/Admin dashboard remain work in progress. The friend's admin email was explicitly deferred. No payment, real identity document or live test booking was fabricated.
