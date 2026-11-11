# Clerk staged exchange implementation plan

> Execute inline with executing-plans and test-driven-development. User chose a trial before switching and requested autonomous completion.

**Goal:** Connect already-existing FIXO accounts to Clerk safely behind a disabled-by-default server flag, without replacing working Firebase login.

**Architecture / spec:** An immutable, private ClerkIdentityLink binds one issuer/subject to one existing FIXO user only after a fresh verified Firebase proof for that user and a live Clerk session proof. No matching by email, user creation, role imports, passwords, SMS, or bulk migration. Exchange issues FIXO sessions carrying the Clerk issuer/subject/session binding; refresh validates the current provider session and link again. Firebase refresh remains unchanged. Clerk sessions do not carry Firebase authentication proof, so existing admin reauthentication remains required. No frontend cutover until real provider credentials and device proof exist.

**Tech stack:** Existing NestJS/Prisma/PostgreSQL and pinned @clerk/backend 3.27.0. Flutter remains the client.

**Constraints:** Free only; never log tokens or provider identities; no live data fixtures; exact trusted issuer/origins; finite provider timeouts; deleted/banned/locked/pending/revoked accounts fail closed. New private table has RLS and no anon/authenticated grants. Use this repository's Prisma migration history rather than a parallel Supabase migration history.

## Tasks

1. Provider boundary: add a live session/account policy with configuration validation and failure sanitization. Tests cover live status, subject/session matching, verified primary email, impersonation, expiry, provider outage and missing credentials. RED then GREEN.
2. Link/exchange and persistence: Prisma private table and two gated trial endpoints. Require both proofs to link, never overwrite either side, verify inside a transaction and handle concurrent unique conflicts. Test wrong user, stale Firebase proof, duplicate/colliding links, deleted account, unlinked exchange. RED then GREEN.
3. FIXO session lifecycle: preserve the Clerk binding through signed access/refresh tokens; recheck link and provider on refresh; preserve Firebase-only behavior and admin boundaries. Test refresh revocation/rotation and disabled trial. RED then GREEN.
4. Verify lint/build/full backend tests against local fixo_test, review all changes, update handoff and push. Deploy only with trial disabled unless real integration prerequisites are satisfied. Review images/push/permissions using existing platform tests and document real-device limits.

## Progress

- Preflight: tasks 1/2 share verified issuer/subject/session; tasks 2/3 share the immutable database link and session binding. Keep those types explicit.
- Decision: trial can only link existing accounts; new-account migration and production switch remain outside this trial. This prevents accidental duplicate users/bookings or email takeover.
- Decision: implementation stays inline at the user's explicit request to avoid Teamwork/subagent quota cost.
- Tasks 1–3 implemented: policy, private identity-link schema/migration, explicit dual-proof HTTP link and exchange, provider-bound FIXO refresh. Initial whole-server verification passed 551 tests in 59 suites, lint and build; real external proofs remain unavailable.
- Found during task 4: firebase_messaging 17 emits FIDs but PushSender used the legacy token field. Four real sender-body regressions failed before the fix. Firebase's canonical FID pattern and HTTP `fid` field are used while retaining legacy token compatibility. Android/iOS FID opt-ins, iOS push/background capabilities and APNs readiness checks are now included. Provider acceptance/OS delivery remain unproven.
- Local database note: pre-existing failed geo migration prevents `prisma migrate deploy` on fixo_test. The new table SQL was executed only against the explicitly validated local fixo_test target, without modifying unrelated migration history. Live migration remains pending while Clerk is disabled.
- Final code verification: 558 backend tests/60 suites, backend lint/build, 565 Flutter tests/two opt-in skips, Flutter analyze all passed. Expired-session cleanup regression was reproduced (two registrations instead of one) and corrected; its focused suite passed 18 tests. No live-provider/device proof is implied.
- Code uploaded as 9a8e5d3. API/Web Ready, Firebase Hosting mirror updated, both Web asset hashes match the local release, health/readiness and anonymous/gated route checks passed. APK rebuilt. Clerk old-key retrieval is blocked by its one-time disclosure policy; separate permission for a new dedicated trial key is pending.
