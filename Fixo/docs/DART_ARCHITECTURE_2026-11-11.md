# Dart transition and cleanup checkpoint

User scope: Flutter/Dart for client, Web and administration **and Dart for the backend**. Flutter itself is not a server runtime. Native platform runners, manifests, SQL/schema history and hosting configuration are required support files, not redundant application implementations.

## Implemented now

- Client application sources under mobile/lib are all Dart (127 files before extraction); administration already runs within that Flutter app. The unused separate admin placeholder and mobile/.gitkeep were removed.
- ProfileRepository and ProfileApiException moved into a framework-free domain contract. DioProfileRepository remains in data; Riverpod construction moved to app/providers. Profile consumers no longer import the concrete repository for dependency injection. The data file re-exports the contract only for existing adapter-test compatibility.
- Architecture regression checks prevent framework, Dio, persistence and outer-layer imports in existing domain files and verify profile dependency composition. This does not imply every presentation feature has been migrated to ports/use cases yet.
- Simplified account setup/login copy, removed the repeated mode pill and replaced an unsupported flag emoji with a native icon. Login/signup/recovery/provider/profile-photo behavior was preserved.
- Removed 104 ignored generated diagnostics/empty placeholders. See CLEANUP_2026-11-11.md. Required assets/licenses, native runners, database migrations and current release evidence remain.
- Created native backend_dart with inward domain/application/infrastructure/presentation dependencies, pinned dependencies/lockfile, bounded PostgreSQL connections, TLS verification for remote databases, read-only catalog transactions, no demo fallback and safe errors.
- Seven Dart tests passed including a real read-only localhost/fixo_test integration. Native executable compilation passed. A real local executable smoke read 21 categories/32 zones, returned healthy/databaseConnected true and kept readiness at 503 MIGRATION_INCOMPLETE. The process was stopped after the smoke check.

## Explicit remaining conversion

96 legacy decorated routes were inventoried. Three initial routes are implemented: health, categories/zones and intentionally closed readiness. **93 routes remain**, including authentication, sessions, booking transactions, payments, private media/chat/support, professional workflows and private administration. See DART_ROUTE_MIGRATION.md and the implementation plan. The live TypeScript backend has not been deleted or replaced; Flutter still targets its working API. This is a real first migration slice, not completion of the full Dart conversion.

Do not delete backend/ until all contracts, authorization, transaction/concurrency regressions and a rollback-capable free-host deployment are verified. Existing Nest backend's 499-test checkpoint remains valid for its unchanged source; Dart does not inherit those passes. Vercel's official function-runtime list does not list Dart. No paid or community runtime was installed and no hosting/billing change was made.

References checked: https://dart.dev/server ; https://pub.dev/packages/postgres ; https://vercel.com/docs/functions/runtimes .

Verification: Flutter analyze clean; 547 Flutter tests passed with two deliberate live opt-in skips. New Dart service analyze clean; seven tests passed including explicit local PostgreSQL. These are separate results, not 499 migrated backend tests. Login golden changes were visually inspected in Arabic/dark and English/light before acceptance. No cloud data or account was altered.
