# Gemini assignment: finish private catalog controls

User authorized Gemini collaboration on2026-11-03. One Gemini implementer only; no Teamwork/subagents. Codex owns notifications, messaging and device lifecycle. Work on the existing fixo-admin-profile checkout; no branch switching, reset, rebase or checkout of files.

Workspace: C:\Users\HP\.codex\worktrees\fixo-admin-avatars\Fixo_Home_Services
Baseline HEAD: dc619b8 (booking/professional administration already deployed).

Read Fixo/AGENTS.md, Fixo/docs/PROJECT_STATUS.md and the existing catalog code. Explicit user authorization supersedes the older admin-later/16-screen scope limit. Keep existing approved Flutter theme/layout; do not claim unavailable live Stitch access.

Implement only the already-approved remaining catalog controls:
1. Create a custom private service draft from the admin catalog. Require explicit bilingual names/descriptions/category and safe unique slug; no fabricated price, duration or availability. Reuse existing draft pricing/versioned explicit publication.
2. Safely deactivate/reactivate a published service through audited AdminMembership authority and fresh confirmation. Preserve bookings, historical pricing, categories and service records. Inactive services must disappear from public listing and reject new bookings; existing bookings remain readable/operable.
3. Protect stale versions, unauthorized users and audit rollback. UI needs clear confirmation, error/retry, EN/AR, light/dark and360/390/412dp at1.35x. Keep logout only in Profile.

Own only admin catalog files, catalog methods/imports in admin_repository.dart, new focused catalog test files, and this assignment's evidence notes. Codex will not edit those files during this assignment. Do not change admin_page.dart or admin_dashboard_test.dart; the catalog navigation already exists. Do not change auth, pro review, booking operations, notifications, picker, incoming-job timing, infrastructure, secrets or live database state. Other than read-only inspection, do not touch the original E: checkout, port3001, or local Flutter5178.

Free existing services only. Never use paid models/scans/trials or enable billing. No real data/dossier/account changes. Never print/read credentials. Run meaningful focused tests; any PostgreSQL tests must validate localhost:5432/fixo_test before connection/writes and run in-band. Do not run the entire backend suite concurrently with another database test run. Do not weaken tests or auto-refresh goldens without inspecting output. No exit(0) shortcuts.

Do not commit, push, deploy, apply a cloud migration or upgrade dependencies. Leave a focused reviewable diff and return changed paths, test evidence and any integration/schema blockers. Codex will review, integrate and release. If the workspace/HEAD differs, use the exact workspace above and report the mismatch before editing any file.
