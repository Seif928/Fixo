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

Latest steering: technician must upload national-ID front, back and criminal-record certificate and await manual approval. Replace specimen-only runtime with actual private uploads; keep all automated fixtures synthetic. No automatic approval. User delegated routine Accept/continue choices; paid services remain forbidden.

Dependency ruling: image_picker latest 1.2.4 requires Dart 3.11 while project uses 3.10.8. Select newest SDK-compatible official plugin; do not upgrade the full Flutter toolchain as a shortcut. npm audit identified existing Multer 2.4 high-severity advisory; target a compatible Multer 2.5 override and verify the multipart flow. Prisma/deepmerge high findings are tooling dependencies and require separate compatibility review.

Checkpoint a61013a committed and pushed to origin/fixo-admin-profile. This is motion/pro entrance/lifecycle only; original branch remains untouched and current new media work is uncommitted. Full mobile baseline for that commit: 294 passed +2 skips, analyze clean.

Current media work: official image_picker 1.2.3 installed (compatible Dart 3.10.8); fake runtime specimen/permission switch removed; actual selected bytes used, cancellation/denial/size/type tests pass (2). Avatar private-storage adapter and controller/service implemented; 8 backend avatar/storage tests pass (decode/resize/EXIF stripping, ownership, failure preservation, orphan cleanup). Flutter optional signup photo and Profile replacement wired; 9 focused UI/picker tests pass including photo failure does not block account setup. Storage credentials/bucket still pending and no live upload claimed. Added Multer 2.5 override: npm install completed, high advisories reduced from5 to3 (remaining Prisma CLI/deepmerge tooling chain). Firebase13.10 pin unchanged. Added iOS camera/photo usage strings. Shared picker Android lost-selection recovery still needs review.

Additional confirmed live-contract defects repaired with red/green tests (4 Pro contract tests now pass): /pro/me envelope, catalog enum string parsing and nested subskills, onboarding verificationStatus plus profile.documents/milestone state/subtitle fields, dashboard earningsSummary/weeklyTrajectory/activeJobs nested fields. These changes are uncommitted. Pro admin review now locks the profile and refuses approval without all3 required documents; real Pro tests12/12 pass. Need complete private object storage for pro documents (currently legacy base64 remains), enforce edit/review lifecycle boundaries, protect original IDs and verify all review decisions.

Next: finish real document Storage and authorized byte access; fix remaining catalog seeding on GET, professional rating/contact defaults, customer address PRO role, and actual Cairo-day earnings labels. Avatar UI needs final formatting/analyze, updated Profile goldens, multipart HTTP guard/size tests and live free Storage configuration. Then resume all27 locations/GPS, admin API/UI, final builds/E2E, Git integration/deployment. Friend email deferred. No live media or admin approval flow verified yet.

Supabase live read confirmed zero buckets. Created and re-read fixo-private bucket through authorized MCP: public=false, max object size2097152, allowedJPEG/PNG/WebP/PDF. No public/authenticated object policies created, no file uploads, no billing changes. Backend write credential still pending; use supported API Keys dashboard flow rather than SQL secret retrieval.

Media checkpoint: actual pro document upload now normalizes photos to WebP, writes private Storage objects and only opaque references in PostgreSQL. Owner/reviewer content endpoint is authenticated and no-store, no expiring-data-URI claims. Guarded real PostgreSQL tests use an isolated in-memory object-store adapter (synthetic images only), while persistence is real local fixo_test. Review, document replacement and identity/skills/submission share profile row locks; reviewed dossiers cannot change until corrections are requested; all3documents are mandatory for approval. Backend suite260/260 in30suites passed after rerunning outside sandbox (the earlier Firebase subprocess EPERM was environmental, not a code failure). Multipart HTTP tests3/3 pass. New private bucket has no public policies; no live document/photo uploaded yet.

Profile now uses a neutral silhouette plus a camera control matching live Stitch Screen10. Inspected live Stitch Screens10/13 through MCP and removed guaranteed payout wording in Pro offer UI. Avatar replacement refreshes current verified profile without restoring stale tokens. User may complete registration without a photo; a failed optional upload preserves the completed account. Profile goldens updated/visually inspected; latest full Flutter verification is running in .vercel/media-mobile-final.log.

Next geography decision: public maintained address catalogs may supply city/village lists as a vendored offline asset with attribution, while manual entry remains available for any missing/new place. Verify license/provenance and parent integrity before importing; never equate a catalog centroid with a user's chosen location or claim exhaustive official accuracy. Canonical27governorates will use real DB coverage entries; actual professionals/availability remain real. Backend seedCatalog already seeds subskills safely, so remove ordinary GET/onboarding seed writes and preserve admin customizations.

Admin delivery ruling: serve the separate React/Vite admin build under existing Web origin /admin/ to reuse the already-authorized Firebase domain and Vercel Hobby project. Keep all membership checks/audits server-side; no new paid service or auth domain is needed. Friend email remains deferred.

Final local evidence for current media/pro increment: full Flutter300 passed +2opt-in skips; analyze0issues; backend260 passed in30suites. Profile camera-control goldens inspected and updated. No live Storage upload, full live technician journey, iOS run or new deployment is claimed. Current changes are ready for a separate milestone commit; booking/review media migration, live credential configuration, national location and admin remain outstanding.
