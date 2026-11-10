# FIXO Dart API — migration in progress

**Inactive experiment — 2026-11-11:** the user stopped this migration and chose the existing working NestJS API. Do not deploy or continue this rewrite unless explicitly requested again. The pending route checklist is historical, not remaining release work.

Native Dart service with domain/application/infrastructure/presentation boundaries. No Flutter runtime, Node process, Nest proxy or demo database fallback.

Implemented: GET `/api/v1/health`, GET `/api/v1/services/categories` (active PostgreSQL categories/zones), GET `/api/v1/health/ready` (intentionally 503 `MIGRATION_INCOMPLETE`). All other endpoints remain unported, returning 404. **Do not point the production client at this service.**

```powershell
dart pub get
dart analyze
dart test
# Explicit local read-only integration verification:
$env:FIXO_DART_DB_TEST='true'
$env:TEST_DATABASE_URL='postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public'
dart test
```

For local startup set `DATABASE_URL` explicitly and run `dart run bin/server.dart`; default bind is `127.0.0.1:3080`. Database URL is never logged. Remote connections require verified TLS. The only supported existing schema is public; no migration/seed/write is executed. Application credentials stay server-side.

Generate the route migration checklist using `dart run tool/inventory.dart`. Complete authentication, authorization, transactional booking/payment behavior, media and all remaining routes before replacing backend/. Retain its Prisma schema/migrations as authoritative until a separately verified migration tool replaces them.

The wire value `POSTGRESQL_PRISMA` is preserved solely for existing client compatibility. Actual Dart persistence uses the postgres driver directly.

Dependencies are pinned in pubspec and pubspec.lock. Use a Dart-compatible host only after full compatibility verification. No free-host deployment or production cutover has been performed.
