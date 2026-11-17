# FIXO account, appointment and support release review

Date: 2026-11-09 (Africa/Cairo). Baseline: 764f9f0; latest Gemini login/logout screens integrated selectively from df0b3f8. The original Gemini checkout remains untouched.

## Implemented behavior
- Login/logout: responsive native Flutter screens; profile remains the normal sign-out entry. Verified provider identity flow is retained, with no email-only Apple/session fallback. Removed unsupported end-to-end encryption/VIP claims; corrected PRO role detection and aligned legacy colors.
- Booking: full calendar plus quick dates; 24-hour exact time picker. The server validates HH:mm, resolves Africa/Cairo DST, rejects past/nonexistent/ambiguous appointments, stores the UTC instant and optional requested local time. Old records retain their time-window display. Customer/payment/technician responses and views carry the exact time and Cairo date.
- Support: customer and technician conversations, dedicated repository/UI, direct technician entry, admin inbox/reply/close. JWT authentication plus user ownership; admin operations revalidate existing Firebase-backed admin membership. Deleted accounts are denied. Empty/oversized messages rejected, bounded reads, 20-open-thread quota protected by a transaction lock; message send/close serialized by database updates. UI preserves a failed-send draft and clears cached content on access denial/account change. Refresh is explicit; no real-time delivery guarantee.
- Architecture: UI uses repositories, API controllers delegate to services, and authorization/pricing remain server-side. No stack replacement or fabricated service/payment data.

## Database
- Added nullable Booking.scheduledTime and private SupportThread/SupportMessage tables; existing records preserved.
- RLS enabled on both support tables; zero anon/authenticated direct grants, two backend-role policies verified.
- Added 14 missing foreign-key indexes plus support sender index. Supabase security advisors returned no lints; unindexed-foreign-key advisory cleared. Unused-index notices retained because the app has limited traffic.
- Live additive migrations: support_exact_time, foreign_key_indexes. No billing change or data deletion.

## Verification
- Full intermediate API suite: 54 suites / 481 tests passed.
- Full intermediate Flutter suite: 538 passed, 2 skipped.
- Final boundary checks: 39 backend tests, then 27 technician/support/time tests passed; 40 final UI workflow/repository tests and 176 responsive/visual tests passed.
- Dart analysis: no issues. API TypeScript compilation passed.
- Final frozen-source API suite: 54 suites / 483 passed. Flutter: 539 passed, 2 skipped. Final web JavaScript/CanvasKit release built to build/web-final; final Android debug APK built. API release compilation passed. Final Dart analysis: no issues.
- Local SQL tests validated localhost:5432/fixo_test before connecting. No cloud destructive tests.

## Practical limits
This is an implementation and focused source/security-boundary review, not proof of absence of all bugs or a completed independent penetration test. Prior security-audit skill ledger was not a full audit; no exhaustive coverage is implied.

Apple sign-in still requires the user's Apple provider setup; electronic payment methods require approved merchant accounts/credentials. No gateway, SMS, paid Apple membership or billing has been activated. Real Google/Apple login, camera/gallery and push delivery on physical devices need user/device smoke checks. iOS build/device validation still requires macOS/Xcode. Firebase project/provider permissions were not changed in this release.

Production release status: API, Vercel web and Firebase Hosting successfully deployed. Final public checks and artifact hashes are recorded below. Database additions are backward compatible. Do not remove the new tables or disable RLS to fix application deployment errors.

## Completed production rollout
- Application source: 57802fd; GitHub branch codex/fixo-premium-repair pushed.
- API: dpl_9M2L5nSxqyqe6Mx8MqFv7s7aULuP (READY), https://fixo-api.vercel.app.
- Web: dpl_5NKL1qnKYhCofcJEdkUghDJ6RS1v (READY), https://fixo-web-blue.vercel.app.
- Firebase Hosting deploy completed at https://fixo-home-services-6507.web.app using firebase.release.json and build/web-final.
- Production readiness: ready, databaseReady true. Unauthenticated support/user and support/admin requests return 401. Apple exchange without a token returns 400.
- Firebase public flutter_bootstrap.js, main.dart.js and firebase-messaging-sw.js SHA-256 hashes match the tested release.
- Previous API rollback: dpl_BdddbQB9b79d1D9eGjh1atWayhyT / fixo-jyqlda49c-gamal6507-3315.vercel.app.
- Previous web rollback: dpl_4JemSNRXi1g5FW8czLWqMbsZ7PGE / fixo-huym1wrfo-gamal6507-3315.vercel.app.
- Android debug test artifact: mobile/build/app/outputs/flutter-apk/app-debug.apk (not a store-signed release).
- No billing, paid service, provider-access or merchant configuration changes.- Vercel public flutter_bootstrap.js, main.dart.js and firebase-messaging-sw.js SHA-256 hashes also match. Direct /support page returns HTTP 200 with the Flutter bootstrap.
