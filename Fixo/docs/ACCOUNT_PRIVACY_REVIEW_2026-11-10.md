# Account and avatar follow-up — 2026-11-10

## Reproduced defects and corrections

1. Account self-deletion checked only the legacy User.role ADMIN value. A real private Owner/Admin membership can belong to a CUSTOMER app account, so local authenticated HTTP tests returned 200 and anonymized the synthetic administrator. UsersService now also checks the private membership: Owner remains protected even when disabled; active, unexpired Admin remains protected. Revoked Admin customer accounts retain ordinary self-deletion rights. Legacy ADMIN protection remains.
2. AvatarService checked account existence after upload but not its isDeleted flag. A delayed upload could therefore restore an avatar reference after account anonymization. The service now rejects a deleted account inside its existing locked write transaction and cleans the newly uploaded object. Reading an avatar for a deleted account also stops before accessing private storage.

These were tested with synthetic local accounts and mocked photo storage. No real account was deleted, altered or used to reproduce either defect. The first finding is an administrator self-deletion/availability defect, not proof of an unauthenticated privilege bypass.

## Regression coverage

- Real guarded PostgreSQL HTTP cases: active Owner, disabled Owner, active private Admin, legacy ADMIN, revoked Admin ordinary deletion, active customer/professional bookings, ordinary customer/professional deletion and session cleanup.
- Real image normalization with mocked storage: deleted-account upload rejects without updating the account and cleans the new object; deleted-account read does not download retained private bytes.
- Existing cloud/private-media cleanup retry limitations and broader account deletion concurrency/retention review remain separate work. These focused corrections do not certify complete data erasure or a comprehensive security audit.

## Release verification

All 499 backend tests in 55 suites passed against the local test setup; TypeScript checking and the Nest build passed. No Flutter source changed in this follow-up; the previously verified 545-test Web/Android release remains in place. Deployment evidence follows after release verification.

- Source 95d6563 pushed to codex/fixo-premium-repair.
- API deployment dpl_C3GicdSKgowQN88YezkjpPhgZwxw is Ready and aliased to https://fixo-api.vercel.app.
- Live health: status ok, POSTGRESQL_PRISMA, databaseConnected true.
- Anonymous avatar read and self-deletion request both return 401. No real account deletion was attempted.
- No database migration, live data repair, billing change, Web redeployment or Apple/payment activation was needed.
