# Clerk trial and native push correction — 2026-11-11

## Delivered behavior

- Clerk remains opt-in and disabled by default. The existing Firebase/Google and phone/password login remains authoritative. No account was imported, linked or changed on the live database.
- Added `POST /auth/clerk/trial/link`: existing FIXO Bearer session, fresh verified Firebase ID token (authentication within 5 minutes), and verified live Clerk session are all required. A transaction and database uniqueness constraints preserve immutable issuer/subject-to-user mapping. Email matches cannot link or create an account.
- Added `POST /auth/clerk/trial/exchange`: only explicitly linked identities can receive FIXO sessions. Their original FIXO IDs/roles remain authoritative. Refresh rechecks the Clerk account/session and database link; revoked, expired, banned, locked, deleted or unverified accounts fail closed. Clerk proof supplies no Firebase administrative reauthentication time.
- Signature verification uses the pinned official Clerk SDK, exact issuer/origins/public signing key, session claims and expiry checks. Impersonation is rejected. Live account/session reads have a bounded wait and sanitized failures. A bounded per-process request limit protects the trial; a production cutover still needs distributed abuse controls.
- `ClerkIdentityLink` migration is private: RLS enabled, PUBLIC/anon/authenticated privileges revoked, existing server-role policy only. It was exercised on local `fixo_test`, including uniqueness, concurrency, access metadata, HTTP guards/DTOs and session rotation. **Not applied to live Supabase.** The live API can safely keep the feature disabled without this table.
- FCM sender now uses `message.fid` for canonical Firebase Installation IDs and preserves `message.token` for older FCM registration tokens. The Firebase SDK's canonical FID pattern is used; no stored registrations were rewritten.
- Android and iOS now explicitly opt into FID registration. iOS project includes Push/Background capabilities, background modes and environment-specific APNs entitlement configuration. Registration checks APNs readiness before calling FCM, has a timeout, and cancels its temporary listener after success/failure/timeout.
- Expired-session native cleanup now shares the same serialization barrier as logout. A new account cannot create its notification registration while an older cleanup is still pending. The regression failed with two registrations before the fix and passed after serialization.

## Verification and rollout

- Final full backend suite: **558 tests / 60 suites passed**, against local `fixo_test`; TypeScript lint and Nest build passed.
- Final Flutter suite: **565 passed, 2 deliberate opt-in skips**; `flutter analyze --no-pub` reported no issues.
- Native configuration parsed successfully: Android FID opt-in, iOS FID/background modes, APNs entitlement and Debug/Release/Profile environment mappings. This is configuration validation, not an iOS compile/runtime test.
- Release Web build and ordinary Android debug APK both succeeded from code commit `9a8e5d3`, pushed to `origin/codex/fixo-premium-repair`.
- API deployment `dpl_9LAuuWLEy5TzKLFrmN8MmPHXGqcJ`, Ready at https://fixo-api.vercel.app (deployment URL https://fixo-pgr57j2sj-gamal6507-3315.vercel.app). Live health 200/ok, PostgreSQL connected, readiness 200, anonymous `/users/me` 401 and gated Clerk exchange 503 as expected while disabled.
- After approved Clerk configuration, the same tested API code was redeployed as `dpl_6X6BD1qQkQcdzq2Xk8rbgfH1qTNE` (https://fixo-jp9jcfu0v-gamal6507-3315.vercel.app), Ready on the same stable API alias. Post-configuration health/readiness passed again, database connected, anonymous profile 401, disabled trial exchange 503.
- Web deployment `dpl_MgQ8aX79Ydcw6cExwcui2tuw8Tq3`, Ready at https://fixo-web-blue.vercel.app (deployment URL https://fixo-c5q6u7cby-gamal6507-3315.vercel.app). Firebase Hosting mirror was updated at https://fixo-home-services-6507.web.app.
- Both deployed `main.dart.js` files match the tested local release SHA256 `E1667CDE13C5909B28C4F43D5CA3309A67EBBF467F1D0A64B7B639D5D280136C`. Live Arabic phone/password/Google login page rendered successfully, with no Web Apple entry.
- APK is local at `mobile/build/app/outputs/flutter-apk/app-debug.apk`, SHA256 `AA346AEB903019C4382511430FDFC5C0272A0114E1BBFA4358D374CA127E1E01`; not a signed store release.

## Prerequisites still open

1. Clerk server configuration is now saved on Vercel `fixo-api` Production: `CLERK_SECRET_KEY` is a Secret; issuer, public PEM signing key and exact trusted Web origins are Config values. `CLERK_TRIAL_ENABLED=false` is explicit. The user separately approved creating `fixo-api-trial`, completed Clerk's email verification privately, and the UI confirmed successful creation. The key was transferred by stdin directly from the temporary Windows clipboard to Vercel; clipboard clearing was verified. No secret entered chat, Git, a local key file, or a screenshot; the old key was not deleted. A real dual-proof client flow and end-to-end trial remain unimplemented/unverified before switching login. The hosted Clerk account portal alone is not FIXO integration. No live identity-link migration, production Clerk instance or bulk migration was created.
2. No Android device is currently attached. Native receipt/display and real camera/permission flows remain unproven; synthetic/regression tests are not delivery evidence.
3. iOS archive, signing, APNs key upload and real-device proof need a Mac/iPhone and the user's Apple account/provisioning. `FIXO_APNS_CONFIGURED` stays false until proof exists. No billing or Apple membership was activated.
4. Electronic payments still require an approved merchant account/provider and a real adapter/webhook implementation; cash remains available. No method was marked operational merely because its UI exists.

## References checked

- Clerk session lookup: https://clerk.com/docs/reference/backend/sessions/get-session
- Clerk token verification: https://clerk.com/docs/reference/backend/verify-token
- Firebase Flutter native setup and FID opt-in: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- Firebase official FID HTTP send example: https://github.com/firebase/quickstart-js/blob/master/messaging/README.md
- Firebase canonical FID format: https://github.com/firebase/firebase-js-sdk/blob/main/packages/installations/src/helpers/generate-fid.ts
- Supabase private-table/RLS guidance: https://supabase.com/docs/guides/database/postgres/row-level-security

## Decisions and limits

The user's explicit single-implementer preference overrides delegated review; the new identity/session boundaries were reviewed inline. No main-branch merge, destructive cleanup, paid service, identity migration or provider cutover is included. Local `fixo_test` has a pre-existing failed geo migration; only the new table SQL was applied to the validated local target, without rewriting unrelated migration history.
