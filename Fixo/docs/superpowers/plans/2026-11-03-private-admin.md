# Private administration implementation plan

User decisions: administration inside FIXO; Owner manages membership, Owner and Admin manage professionals, services, prices and bookings. Two people maximum. Friend email deferred. Single implementer; no agents. User now requests a choice before each new product feature.

## Current approved increment: access and audit foundation

- [x] Add private AdminMembership (fixed slots1Owner/2Admin) and AdminAuditLog tables, with RLS and backend-only access.
- [x] Require current verified Firebase identity matching the stored account email, independent of User.role. Bootstrap only the configured owner email on first verified access. Invites expire after7days and bind to the actual verified account.
- [x] Implement GET/admin/me, GET/admin/members, PUT/admin/member, DELETE/admin/member and GET/admin/audit. Membership management is Owner-only; writes require provider authentication within15minutes.
- [x] Serialize membership mutations and recheck current authority in the same transaction as a safe audit event; no passwords, tokens or identity-document content in audit payloads.
- [x] Test unauthorized/role-spoofed access, wrong provider identity, concurrent bootstrap, second-member binding, third-slot denial, expired invites, revocation races and transaction rollback against guarded localhost/fixo_test.
- [x] Run backend checks:310tests/38suites, TypeScriptlint and production build passed. Local migration only; no live membership/configuration or deployment.
- [ ] Ask the user for the dashboard layout before frontend work or implementing the next operations feature.

## Subsequent decisions and increments

Dashboard layout (desktop sidebar/mobile adaptation), then manual professional review/private document viewing with no self approval; catalog editing/soft deactivation; booking operations constrained by actual state/payment; genuine summary counts and audit trail. These operations must use AdminMembership, including legacy reviewer entry points; app roles alone never grant dashboard authority.

Accepted later product ideas remain pending: favorites and repeat booking, complaints, professional schedules/leave, account deletion and data controls. Ask about meaningful product behavior before each increment. Keep free development hosting, no SMS/billing, port3001 and the running local Flutter5178 session intact. Authenticated live UI verification was explicitly deferred by the user. Formal security audit remains incomplete.
