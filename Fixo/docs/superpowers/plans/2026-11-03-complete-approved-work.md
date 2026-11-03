# Complete the approved FIXO backlog

Authority: docs/PROJECT_STATUS.md and the user's2026-11-03instruction to implement all previously requested work, provide ideas/opinion, keep costs zero and use one implementer. Continue inline; do not pause merely to ask whether to continue. Existing approved manual professional review is first.

Ruling: keep this native Windows plan/ledger instead of Bash bookkeeping, and self-review rather than dispatch a reviewer because the user forbids Teamwork/subagents. Current worktree fixo-admin-profile is already isolated; original checkout/port3001 and Flutter5178 remain intact. Original Stitch tooling is unavailable; retain existing native design tokens and responsive shell, without claiming a new live Stitch fetch. User authorization overrides older16-screen/admin-later limits.

Pre-flight interfaces: AdminAccess provides verified membership/fresh confirmation and a serial authority/audit transaction; ProService currently uses a legacy app-role reviewer bypass. Convert both legacy review/document routes and new admin routes before exposing professional review. Booking/dispatch follow the Booking→ProProfile→JobOffer lock order; review must not acquire Booking locks after ProProfile. Later schedules/complaints/media must preserve that order and historical prices. Private object storage is configured and bounded; do not expose keys, ID images or personal content in logs/audits. Real authenticated UI verification remains user-deferred.

##1Professional administration — verification/release

- Test first: ordinary app ADMIN cannot review/read another person's documents; actual Owner/Admin can; self-review, old proof, missing documents and stale dossier snapshots fail without writes/audit. Decision and audit roll back together. All fixtures local/synthetic.
- Add paginated/searchable professional list and selected dossier details with explicit safe field selection. List omits national ID; detailed identity and document images are private/no-store.
- Use a dossier hash of actual profile/document revision for review concurrency. Remove bool/app-role access bypasses. Require explicit document-review confirmation and notes for corrections/suspension; preserve customer identity roles and no automatic online/approval. Record private-document access grants without personal contents.
- Native admin list/detail, bounded private image viewing, manual decision dialog, EN/AR/themes/responsive tests and failure/reconfirmation behavior.
- Verify backend/mobile suites, build, source/deployment and live anonymous denial; do not approve any real dossier during testing.

2026-11-03 implementation evidence: private paginated queue/dossier, versioned manual decisions and fresh-proof transactional audit implemented. Legacy app-ADMIN review and document bypasses removed. All three required images must decode and be reviewed before the UI permits approval; selected correction reasons return through the existing professional feedback flow. An open dossier/image permanently clears after logout/account change, even if the same account returns. The ordinary-user membership probe rejects before external Firebase lookup. Backend 321 tests/40 suites passed; full Flutter370 passed with2existing opt-in skips; focused native UI28 passed; analyze0 issues, lint/backend build passed. Clean desktop/Arabic-dark390dp visual snapshots inspected. Web release build and deployment verification pending. Synthetic fixtures/local fixo_test only; no real identity reviewed or approved.

##2Booking administration

Paginated actual bookings/details/status history; constrained cancellation/dispatch/assignment and cash integrity. No fabricated completion/payment transitions. Implement actual permissions and audited state changes; preserve historical pricing and assigned pro eligibility.

##3Notifications, messages and device lifecycle

Review/complete foreground/background/logout behavior and permission requests; tests and available-device checks. Add Android picker lost-data recovery and monotonic offer resume timing. Record genuinely unavailable iOS/APNs/device verification rather than fabricating success.

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
