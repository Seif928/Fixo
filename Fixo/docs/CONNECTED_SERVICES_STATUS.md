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
- Contextual device-push opt-in, denial/unavailable states, token refresh, sign-out unregister, foreground alerts and notification navigation.
- Embedded OpenFreeMap styles/tiles through MapLibre, with required OpenStreetMap/OpenMapTiles attribution. No key, account, billing or paid Maps API. A Cairo overview is not a selected address: the user explicitly picks a coordinate, and the existing address API persists it. No GPS permission, geocoding or live technician tracking is claimed. Public Google Maps links remain available for directions.
- Public Firebase Web service worker, with an explicit no-cache response header in the static deployment configuration.
- Android release INTERNET and notification permissions, Firebase config, debug signing fingerprints, Kotlin/R8 compatibility configuration; iOS minimum target 15 with Google sign-in callback configuration.
- Gemini's completed presentation changes integrated: EN/AR RTL, Light/Dark/System, bundled Manrope/Cairo fonts and licenses, readable real-font golden screenshots, professional app/Web icons and metadata, and responsive forms/cards.
- Customer bottom navigation opens the correct Home/Orders/Chat/Profile route, marks the selected tab accessibly, and preserves Home state while changing peer tabs. Screen 08 reads real bookings with status filters, pagination, retry and pull-to-refresh. Chat lists actual assigned booking conversations; it does not invent contacts.
- Removed the unsupported brand-certified promo badge and the claim of a 24/7 concierge; the same design area now explains the actual booking process. Onboarding no longer invents a technician count, arrival estimate, identity-review process or live tracking.

## Verification evidence and limits

- Backend lint/build passed and all 227 tests/23 suites passed, including real PostgreSQL tests for one-time profile setup, conflicts and device-registration races. Tests use only the guarded local fixo_test target.
- Flutter analyze passed and 257 tests passed (2 explicit live checks skipped). The UI checks include 144 combinations of 360/390/412dp, 1.35x text scale, EN/AR and Light/Dark, plus 18 real-font golden images. These are test fixtures, not fabricated production users or bookings. Logout also revokes the latest refresh token if push unregister triggered rotation.
- Integrated release Web and Android builds passed with the API above. Web contains the fonts and FCM service worker. Android APK is about 83.9 MB with native MapLibre; signing is still the development/debug key, not a Play Store release setup.
- Deployed API readiness and live catalog reads returned HTTP 200 with PostgreSQL persistence. Public OTP request returned HTTP 503, as intended.
- FCM service-account validation reached the live FCM v1 API and returned INVALID_ARGUMENT for a deliberately invalid, validation-only token. This verifies API authorization, not delivery to an actual device.
- User approved real Google sign-in and browser notification testing with the configured Google account. No live account sign-in or real-device notification delivery has yet been verified.
- The deployed Web login rendered correctly in the real browser and opened Google's account chooser. Browser control stalled while selecting the authorized account; the user must complete that step and enter the new password in the app. Do not treat this as a successful account setup or notification-delivery test.

## Remaining live verification

Gemini has finished and its changes are integrated. The final live Google/profile/password setup and notification delivery still need runtime verification. User approval for Google identity sharing and browser notifications is already recorded. Creating the new password must be completed by the user in the app; never ask for it in chat or choose one on the user's behalf. Do not create cloud bookings/payments for this account test.

iOS runtime/APNs remains unavailable without appropriate Apple credentials and a macOS/Xcode test environment. Do not claim it works. SMS remains disabled. No real professionals/dispatch/tracking/reviews have been fabricated; missing product workflows remain separate development work.

## Reproduction

Configure server variables from backend/.env.example with independent secrets. Local integration tests must target explicit localhost:5432/fixo_test and pass the existing fail-closed guard. Native Firebase configuration files are deliberately ignored: regenerate them with FlutterFire against the approved project. Public Firebase client options and the Web service worker contain no service-account secret.

Build Web using `flutter build web --release --dart-define=FIXO_API_BASE_URL=https://fixo-api.vercel.app/api/v1`. Copy `mobile/vercel.static.json` to `mobile/build/web/vercel.json` and the locally linked `.vercel/project.json` into `build/web/.vercel/project.json`, then run `vercel deploy --prod --yes` from `build/web`. Deploying source mobile/ as a guessed framework is not the static-artifact deployment used here.

Brand icons reuse the existing Material `handyman_rounded` glyph from FixoBrandMark. Re-export with `python tool/generate_brand_icons.py <Flutter SDK>/bin/cache/artifacts/material_fonts/materialicons-regular.otf` (Pillow required). The font is supplied/licensed by the Flutter SDK; no new remote logo service is used.

## Google sign-in on Vercel: runtime compatibility fix

The reported cloud-only Google failure reached `/auth/firebase/session` but was rejected before first-profile setup. Safe server diagnostics confirmed matching Firebase audience/issuer and `ERR_REQUIRE_ESM`. The actual Firebase Admin 14 -> jwks-rsa 4 -> jose 6 dependency chain failed under the CommonJS loader; a real-SDK subprocess test reproduced the same failure with `--no-experimental-require-module`. See the [upstream Firebase issue](https://github.com/firebase/firebase-admin-node/issues/3181).

Firebase Admin is deliberately pinned to the official 13.10.0 release, whose dependency chain supports this loader. Keep this pin until a newer version passes `firebase-runtime.spec.ts` and the cloud sign-in check. Signature, issuer, audience and expiry verification still use the SDK's `verifyIdToken`; no unsigned token, emulator or fabricated identity fallback was added. Diagnostics record only safe error codes and match booleans, never tokens, provider messages, email or user IDs.

Client errors now distinguish a rejected Google/session exchange from an incorrect phone/password and distinguish Google account conflicts from phone conflicts. The intended flow remains Google -> name/phone/password once -> Home; later login uses phone/password without SMS.

Post-fix validation: backend lint/build and 230 tests/25 suites passed; Flutter analyze and 272 tests passed with 2 opt-in live suites skipped; the integrated Web build passed. Gemini's visual QA commit is 2082e65 and remains preserved. Real completion of the first-profile form and device notification delivery still require the user's runtime interaction. Existing npm audit findings in the Nest/Multer/Prisma dependency chains are outside this targeted Firebase compatibility fix; Firebase is not among the reported high-severity dependencies.
