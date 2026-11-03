# Private administration implementation plan

User decisions: administration inside FIXO; Owner manages membership, Owner and Admin manage professionals, services, prices and bookings. Two people maximum. Friend email deferred. Single implementer; no agents. User now requests a choice before each new product feature.

## Current approved increment: access and audit foundation

- [x] Add private AdminMembership (fixed slots1Owner/2Admin) and AdminAuditLog tables, with RLS and backend-only access.
- [x] Require current verified Firebase identity matching the stored account email, independent of User.role. Bootstrap only the configured owner email on first verified access. Invites expire after7days and bind to the actual verified account.
- [x] Implement GET/admin/me, GET/admin/members, PUT/admin/member, DELETE/admin/member and GET/admin/audit. Membership management is Owner-only; writes require provider authentication within15minutes.
- [x] Serialize membership mutations and recheck current authority in the same transaction as a safe audit event; no passwords, tokens or identity-document content in audit payloads.
- [x] Test unauthorized/role-spoofed access, wrong provider identity, concurrent bootstrap, second-member binding, third-slot denial, expired invites, revocation races and transaction rollback against guarded localhost/fixo_test.
- [x] Run backend checks:310tests/38suites, TypeScriptlint and production build passed. Local migration only; no live membership/configuration or deployment.
- [x] User chose a desktop sidebar and mobile drawer. Implemented authenticated /admin, profile-only entry, genuine summary, Owner-only membership and latest20audit pages, current-account password reconfirmation and immediate clearing/cancellation on identity changes.
- [x] Verification:311backend tests/38suites;356Flutter tests with2existing opt-in skips;15focused administration tests; analyzed clean; desktop EN/mobile AR-dark visual snapshots reviewed. Deployment still pending.

## Approved expansion (2026-11-03)

User chose home maintenance, appliances, moving, cleaning, gardens and pest control. New services are private drafts; the owner sets actual prices and publishes through administration. No invented prices and no new public/bookable services until explicit publication. Keep existing services and bookings unchanged. Add native responsive catalog management for Owner/Admin, validated draft updates and versioned publication with an atomic audit. Use a separate draft table so incomplete pricing never enters public offering DTOs. Seed a curated bilingual catalog idempotently without overwriting edits. Extend mobile/desktop checks and genuine public isolation tests. Paid quotations/inspection workflow was not selected.

- [x] Private draft table/RLS and138curated bilingual service drafts in21groups; existing8offers imported as linked published records. Explicit idempotent seeding preserves operator edits.
- [x] Catalog list/edit/publish uses two-person authority, fresh proof and same-transaction audit. Publication is version-bound, duplicate-safe, and leaves live prices unchanged when only a draft is saved.
- [x] Responsive search/category filters, draft editor and explicit publication preview. Wider desktop marketplace category/professional grids preserve the narrow mobile layout.
- [x] Verification:314backend tests/39suites,361Flutter tests with2existing skips,19admin UI checks, lint/analyze/builds. Local PostgreSQL checks cover privacy, null pricing, stale versions, duplicate publication, Owner/Admin scope, pagination and preservation.
- [x] After an explicit additional user approval, both live migrations applied to fixo-dev; verified all3tables use RLS/backend-only policy, anonymous/authenticated SELECT revoked;138private drafts/8linked offers/21groups, public8offers/6categories, no initialized admin members. Server Owner email configured. No billing enabled.
- [ ] Upload and verify staged deployments, promote existing aliases, push the tested work branch, and record release identifiers. Authenticated live UI testing remains user-deferred.

## Subsequent decisions and increments

Dashboard layout (desktop sidebar/mobile adaptation), then manual professional review/private document viewing with no self approval; catalog editing/soft deactivation; booking operations constrained by actual state/payment; genuine summary counts and audit trail. These operations must use AdminMembership, including legacy reviewer entry points; app roles alone never grant dashboard authority.

Accepted later product ideas remain pending: favorites and repeat booking, complaints, professional schedules/leave, account deletion and data controls. Ask about meaningful product behavior before each increment. Keep free development hosting, no SMS/billing, port3001 and the running local Flutter5178 session intact. Authenticated live UI verification was explicitly deferred by the user. Formal security audit remains incomplete.
