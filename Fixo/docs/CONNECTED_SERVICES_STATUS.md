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

- Verified email and Google sign-in; secure token storage, server-verified session restoration and local sign-out cleanup.
- Persisted language and theme preferences; native chat, profile/settings and in-app activity sheet.
- Contextual device-push opt-in, denial/unavailable states, token refresh, sign-out unregister, foreground alerts and notification navigation.
- Public Firebase Web service worker added. Google Maps uses public address/directions URLs; embedded Maps and GPS selection are not active.
- Android release INTERNET and notification permissions, Firebase config, debug signing fingerprints, Kotlin/R8 compatibility configuration; iOS minimum target 15 with Google sign-in callback configuration.

## Verification evidence and limits

- Backend lint passed and all 216 tests/20 suites passed, including a PostgreSQL concurrent-device-limit regression test. Registrations serialize per user and per token to prevent limit bypass and cross-account token races.
- Flutter analyze passed and 80 tests passed (2 explicit live checks skipped) before concurrent Gemini presentation edits started.
- Release APK built successfully (52.7 MB), using the API above, before the latest presentation edits. This is a debug-signed development artifact, not a Play Store signing/release setup or a claim of runtime verification.
- Deployed API readiness and live catalog reads returned HTTP 200 with PostgreSQL persistence. Public OTP request returned HTTP 503, as intended.
- FCM service-account validation reached the live FCM v1 API and returned INVALID_ARGUMENT for a deliberately invalid, validation-only token. This verifies API authorization, not delivery to an actual device.
- User approved real Google sign-in and browser notification testing with the configured Google account. No live account sign-in or real-device notification delivery has yet been verified.

## Pending integration gate

Gemini owns presentation/theme/localization polish. Preserve its concurrent changes; do not commit or overwrite its work. During a Web build, its email screen contained `Icons.mark_email_Read_outlined`, which is not a valid Flutter icon. Wait for Gemini's completed/verified design before the final integrated Web/APK build and Google/push runtime tests.

After Gemini finishes: inspect its diff, run analyze/full Flutter tests, rebuild Web/APK, deploy the verified Web artifact including firebase-messaging-sw.js, and perform the approved sign-in/notification tests. Review and stage the task's design changes without including unrelated files. The user has already authorized committing and pushing the reviewed project work.

iOS runtime/APNs remains unavailable without appropriate Apple credentials and a macOS/Xcode test environment. Do not claim it works. SMS remains disabled. No real professionals/dispatch/tracking/reviews have been fabricated; missing product workflows remain separate development work.

## Reproduction

Configure server variables from backend/.env.example with independent secrets. Local integration tests must target explicit localhost:5432/fixo_test and pass the existing fail-closed guard. Native Firebase configuration files are deliberately ignored: regenerate them with FlutterFire against the approved project. Public Firebase client options and the Web service worker contain no service-account secret.
