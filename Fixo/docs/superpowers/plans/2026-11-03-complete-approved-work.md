# Complete the approved FIXO backlog

Authority: docs/PROJECT_STATUS.md and the user's2026-11-03instruction to implement all previously requested work, provide ideas/opinion, keep costs zero and use one implementer. Continue inline; do not pause merely to ask whether to continue. Existing approved manual professional review is first.

Ruling: keep this native Windows plan/ledger instead of Bash bookkeeping, and self-review rather than dispatch a reviewer because the user forbids Teamwork/subagents. Current worktree fixo-admin-profile is already isolated; original checkout/port3001 and Flutter5178 remain intact. Original Stitch tooling is unavailable; retain existing native design tokens and responsive shell, without claiming a new live Stitch fetch. User authorization overrides older16-screen/admin-later limits.

Pre-flight interfaces: AdminAccess provides verified membership/fresh confirmation and a serial authority/audit transaction; ProService currently uses a legacy app-role reviewer bypass. Convert both legacy review/document routes and new admin routes before exposing professional review. Booking/dispatch follow the Booking→ProProfile→JobOffer lock order; review must not acquire Booking locks after ProProfile. Later schedules/complaints/media must preserve that order and historical prices. Private object storage is configured and bounded; do not expose keys, ID images or personal content in logs/audits. Real authenticated UI verification remains user-deferred.

##1Professional administration — released e3f75dc

- Test first: ordinary app ADMIN cannot review/read another person's documents; actual Owner/Admin can; self-review, old proof, missing documents and stale dossier snapshots fail without writes/audit. Decision and audit roll back together. All fixtures local/synthetic.
- Add paginated/searchable professional list and selected dossier details with explicit safe field selection. List omits national ID; detailed identity and document images are private/no-store.
- Use a dossier hash of actual profile/document revision for review concurrency. Remove bool/app-role access bypasses. Require explicit document-review confirmation and notes for corrections/suspension; preserve customer identity roles and no automatic online/approval. Record private-document access grants without personal contents.
- Native admin list/detail, bounded private image viewing, manual decision dialog, EN/AR/themes/responsive tests and failure/reconfirmation behavior.
- Verify backend/mobile suites, build, source/deployment and live anonymous denial; do not approve any real dossier during testing.

2026-11-03 implementation evidence: private paginated queue/dossier, versioned manual decisions and fresh-proof transactional audit implemented. Legacy app-ADMIN review and document bypasses removed. All three required images must decode and be reviewed before the UI permits approval; selected correction reasons return through the existing professional feedback flow. An open dossier/image permanently clears after logout/account change, even if the same account returns. The ordinary-user membership probe rejects before external Firebase lookup. Backend 321 tests/40 suites passed; full Flutter370 passed with2existing opt-in skips; focused native UI28 passed; analyze0 issues, lint/backend build passed. Clean desktop/Arabic-dark390dp visual snapshots inspected. Web release build and deployment verification pending. Synthetic fixtures/local fixo_test only; no real identity reviewed or approved.

Release evidence: backend/Web builds passed; source e3f75dc pushed. Staged API ready/anonymous professional route401; staged Web hash matched build. Promoted API dpl_Hfk2G9o2EwVL8wRj4qhR8aVPBMQ6 and Web dpl_GUcbjgMgDcDiDwnfWhaV5UQ7XzBe. Stable readiness200, private queue401, public catalog8, /admin shell200/cache retirement and exact Web hash verified. The earlier pending Web-build statement is superseded. Authenticated review remains deferred; no real dossier approved.

##2Booking administration — released12a9a6c

Paginated actual bookings/details/status history; constrained cancellation/dispatch/assignment and cash integrity. No fabricated completion/payment transitions. Implement actual permissions and audited state changes; preserve historical pricing and assigned pro eligibility.

Implemented private booking queue/search/status paging, fresh-confirmed details/history without arrival PIN/storage references, versioned pre-service unpaid cancellation and explicit offers to eligible approved online professionals. Sending an offer does not assign a pro; actual professional acceptance was verified over HTTP/SQL. Prices/payment amounts remain unchanged, pending cancellation becomes FAILED without a paidAt, duplicate offers/cancellation do not duplicate audit or history. Rejected/stale/revoked members, coverage/category/self-dispatch, changed snapshots and paid/started work fail closed. Actual database writes roll back if the audit insert fails. Removed every isAdmin argument/ownership bypass from customer booking/media-token services and controllers, with legacy tests updated to require ownership.

Regression: a newly introduced expression-bodied setState returned the list Future after an operation; the two workflow tests reproduced it, then synchronous state assignment fixed it. Also guard pending professional decisions if logout occurs while their confirmation dialog is open. Private booking details/actions clear and stay invalid after logout and restoration. Arabic dark360/390/412 at1.35x, conflict handling and clean golden inspected. Backend329/41suites; focused administration36; Flutter378+2existing opt-in skips; lint/analyze/build passed. Web build/commit/deployment pending. All synthetic/local tests; no real booking was changed.

Release evidence: Web/backend builds passed; source12a9a6c pushed. API dpl_CaB3VZ2FVnzqvy3KPXebvGYAJSUC and Web dpl_8AxwApUSdFLAbjtNAdcxwA5GXkVT staged then promoted. Stable database readiness200; booking list/detail/candidates and professional queue401 anonymously; public catalog remains8. Staged/stable Web SHA256 0F2FFBC67FD31298461508B1E80B2751ED7EC0FF8A78408B3C48E9C98F6D03BF matches the build, /admin shell and cache retirement passed. Earlier pending-build/commit/deployment text is superseded. Actual authenticated operational testing remains deferred. No real booking or dossier changed.

##3Notifications, messages and device lifecycle — in progress (Codex)

Review/complete foreground/background/logout behavior and permission requests; tests and available-device checks. Add Android picker lost-data recovery and monotonic offer resume timing. Record genuinely unavailable iOS/APNs/device verification rather than fabricating success.

Codex working diff: incoming offers now revalidate on foreground resume, ignore stale responses, derive time from a monotonic server budget and recheck it on action. Same revision cannot replenish the budget. Removed a fixed15% display claim; actual returned fees remain unchanged. Twelve mobile width/language/theme cases reproduced and closed existing overflow issues; readable time-window labels replace raw enum text. Android lost-photo handling records only a short-lived account/form tag, reads once on startup, retains photos only in memory and requires decoded preview plus explicit use/discard. Logout/account changes permanently invalidate an open picker, including late results and same-account restoration. Review photos are scoped to their booking, issue photos to their service. Length checked before reading2MB maximum. Whole Flutter analyze0 issues and47 focused lifecycle/photo/pro/asset tests passed. Actual Android process-kill/camera flow and iPhone/APNs delivery remain unverified; no new release or paid service enabled. Notifications/logout delivery cleanup review is still in progress.

Collaboration update: the user explicitly authorized working with Gemini to accelerate delivery. This supersedes the earlier single-implementer preference only for one Gemini implementer alongside Codex; do not start Teamwork or additional Codex subagents. The user confirmed sending the catalog handoff and returned Gemini's completion report (attachment67b7e038-2af1-4245-baaa-dafb139b5fb0). Its local diff/migration remain unstaged and not deployed. Codex found a pending-price version-marker issue on deactivation/reactivation; Gemini's next bounded assignment is2026-11-03-gemini-favorites-repeat-handoff.md: close that catalog regression first, then persisted favorites and current-price repeat booking. Codex owns notifications/lifecycle/media. Preserve each other's files and run no concurrent destructive SQL suites or Gemini deployment/index mutations.

##4Private booking/review media

Replace remaining inline/HMAC media with owned private objects, bounded image normalization, authenticated access and cleanup/failure behavior. Reuse configured free storage.

##5Favorites and repeat booking

Persist actual service/pro favorites and repeat booking using current prices/availability. No copying obsolete booking totals into a new booking.

##6Complaints

Owned complaint creation/status/private optional images; restricted admin handling and actual notifications/audit.

##7Professional schedules and leave

Explicit working days/leave, real eligibility filtering and protection of existing bookings. Consult only for genuinely unspecified product tradeoffs.

##8Account deletion/data controls

Concrete user-confirmed identity flow and documented retention/deletion behavior, revoke sessions and protect administration ownership. No real account/data deletion by the agent. Any unresolved retention/destructive action requires a specific user choice after a reviewable implementation exists.

##9Catalog controls

Custom service draft creation and safe soft deactivation; preserve existing bookings and prevent new bookings of inactive services. Continue actual pricing/versioned publication.

##10Security/code/design review and integration

Resume the explicit audit with the installed skills, maintain honest coverage, review dependencies and findings with regressions. Installing Strix does not imply a scan; no paid model/cloud runs. Integrate original/Gemini work without discarding changes, verify available builds/device flows, commit/push/deploy authorized verified increments. Record unavailable signing/paid Apple-distribution requirements without enabling billing. Do not claim all bugs fixed or the entire audit complete until its evidence exists.
