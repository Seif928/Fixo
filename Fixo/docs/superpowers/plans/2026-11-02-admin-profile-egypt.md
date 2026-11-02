# FIXO Admin, Media and Egypt Coverage Implementation Plan

> Execute inline with superpowers:executing-plans, task by task. User forbids subagents/Teamwork.

**Goal:** Working personal photos, Egypt-wide manual/GPS location, protected owner/admin operations and repaired lifecycle behavior.
**Architecture:** Existing NestJS/Prisma/Firebase authentication; private object storage; native Flutter; separate static React admin using the same authorized API.
**Spec:** ../specs/2026-11-02-admin-profile-egypt.md
**Workspace:** managed fixo-admin-avatars worktree, branch fixo-admin-profile, starting at 16149b5.

## Constraints and review focus
- Free services only; no SMS/billing/trials; owner gamal6507@gmail.com; friend deferred.
- Preserve application roles when granting dashboard membership. Never authorize via a client-supplied role or email.
- Media failures/cancellation must preserve the current avatar and must not destroy a completed first profile.
- Concurrent job transitions must not produce multiple completion events/counts or escape cancellation/PIN limits.
- Manual location selection must work when GPS/reverse geocoding is denied or unavailable; never invent an address.
- Admin edits preserve historical prices and have an audit record; revoked admins lose API access immediately.

## Tasks
- [x] Review new Gemini commits and run baseline checks: 246 backend tests; 279 Flutter tests (+2 opt-in skipped); analyze clean. Inspect high-risk source rather than relying on the report.
- [x] Create native isolated worktree; copy only ignored configuration; verify ignore rules.
- [x] Install existing backend/mobile dependencies in the isolated checkout and preserve clean baseline.
- [x] Repair ProService transition/PIN transaction boundaries; real concurrent completion/PIN-limit regressions failed first and pass after row locking and committed failure attempts. Full backend suite: 246/246. Cancellation uses the same Booking row lock; additional cross-operation review remains.
- [ ] Add private object storage adapter with bounded requests and actual media metadata; validate/decode images, limit file size, remove EXIF and protect access. Replace runtime data-URI/specimen flows. Verify ownership and storage failure behavior.
- [ ] Add users/me/avatar API and expose avatar metadata in verified profiles. Add real Flutter image selection, optional first-profile preview/upload and Profile replacement with clear errors. Remove Home logout and cover navigation/profile behavior.
- [ ] Add 27-governorate catalog and persistent explicit location selection. Wire list selection to feed/address/booking data. Add one-shot permission-aware GPS and provider reverse geocoding with caching/rate limits. Test manual flow, denial, timeout and out-of-Egypt handling.
- [ ] Add AdminMembership/AdminAudit/configuration migrations with RLS restricted to server role; bootstrap only the approved Owner. Enforce owner/admin permissions and max-two active memberships. Add guarded admin APIs for operational sections with validation, pagination, transactional audit and concurrency tests.
- [ ] Design/build responsive admin client in admin/ with existing FIXO branding, real API state, Google sign-in, owner-only membership controls, EN/AR and themes. No fabricated charts/data or infrastructure-secret settings.
- [ ] Review remaining application/backend/design defects, patch concrete findings with regression checks, refresh documentation and visually inspect intended golden changes.
- [ ] Run appropriate final suites, Web/APK/admin builds and browser/local E2E, configure required free Storage/provider services, deploy verified artifacts and check live behavior. Preserve real-user password handoff and no cloud test bookings.
- [ ] Commit/push each verified milestone; integrate into the task branch without discarding concurrent user/Gemini changes. Report actual completed work and concrete outstanding actions.

- [x] Polish finite entrance/page/button motion with reduced-motion support; separate public professional entry and persist navigation intent through Google registration. Resume server-authorized professional onboarding/review/dashboard, preserving customer use of the same identity. Verify responsive UI and API envelope contracts.

## Progress / handoff
2026-11-02: lifecycle concurrency fixed and full 246-test backend suite passed. Motion helpers, shared button feedback and Home logout removal implemented; focused checks in progress. Professional entry requested in latest user steering: separate entry/navigation, same verified identity, no automatic role grant. Found and fixed real /pro/me envelope mismatch. Contract regression failed before the fix. Work is not yet deployed.

Ruling: native Windows inline execution uses this plan as the persistent ledger instead of invoking Bash bookkeeping scripts; no subagents because user explicitly forbids them. User-authorized commit/push/deploy continues without repeated permission prompts. Motion uses finite transforms/opacity and honors reduced-motion instead of perpetual loops: phone performance and accessibility take priority.

Storage status: Storage write credentials are not configured in the known backend environment. Existing Supabase connector exposes publishable keys only; use a supported existing credential/connection flow, never derive signing keys through SQL. Dashboard work was previously out of scope in AGENTS.md; the user's latest explicit instruction authorizes it now. The friend email remains deferred and must not block independent implementation.

Motion/pro entry milestone: flutter analyze clean; full Flutter suite 294 passed, 2 opt-in skips. Explicit variable-font weight and English locale keep the FIXO wordmark stable across screen/test order. Updated and inspected onboarding goldens and related brand references. Real avatar/storage tests are now written and awaiting implementation; these remain outside the first milestone commit.
