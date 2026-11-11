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
- Web/APK builds and live rollout are being recorded after their commands finish.

## Prerequisites still open

1. Clerk server secret/public signing key and exact trusted origins are not configured on Vercel. A real dual-proof client flow and end-to-end trial must pass before switching login. The hosted Clerk account portal alone is not FIXO integration. No production Clerk instance or bulk migration was created.
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
