# FIXO — PostgreSQL Database Setup Guide (`docs/DATABASE_SETUP.md`)

## 1. Prerequisites
- Docker & Docker Compose OR a local PostgreSQL 16+ daemon.
- Node.js 20+ and npm.

---

## 2. Docker Compose Quickstart
To launch the official PostgreSQL 16 container for FIXO development:

```bash
# Start PostgreSQL container on port 5432
docker run --name fixo-postgres \
  -e POSTGRES_USER=fixo_user \
  -e POSTGRES_PASSWORD=fixo_dev_password \
  -e POSTGRES_DB=fixo_dev \
  -p 5432:5432 \
  -d postgres:16-alpine
```

Verify connection:
```powershell
# Windows PowerShell
Test-NetConnection -ComputerName localhost -Port 5432
```

---

## 3. Dedicated Databases

The FIXO architecture uses two isolated PostgreSQL databases on the same instance:

1. **`fixo_dev`**: The local development database used when running the backend application (`npm run start:dev`).
2. **`fixo_test`**: A dedicated, isolated test database used exclusively for the real PostgreSQL integration test suite (`auth-postgres.integration.spec.ts`).

To initialize the test database:
```sql
-- Connect via psql or pgAdmin and run:
CREATE DATABASE fixo_test;
```

---

## 4. Prisma Migrations & Schema Deployment

Prisma migrations manage the 19 public schema tables (including `User`, `OtpChallenge`, `RefreshToken`, etc.):

```bash
cd backend

# Validate Prisma schema
npx prisma validate

# Development: Apply existing migrations and sync dev database
npx prisma migrate dev --name init_fixo_schema

# Dedicated Test Database: Deploy migrations without resetting
$env:DATABASE_URL="postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public"
npx prisma migrate deploy
```

> **Note:** Seed scripts have not yet been implemented. Do **not** run nonexistent seed scripts (e.g. `npm run prisma:seed`).

---

## 5. Environment Configuration

Configure `backend/.env`:
```env
DATABASE_URL="postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_dev?schema=public"
TEST_DATABASE_URL="postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public"
ALLOW_IN_MEMORY_FALLBACK="false" # Strictly enforce real PostgreSQL connectivity
```

When `ALLOW_IN_MEMORY_FALLBACK="false"`:
- The backend verifies live PostgreSQL connectivity on boot via `PrismaService.checkReadiness()`.
- If PostgreSQL is unreachable or credentials fail, the server terminates immediately rather than silently falling back to ephemeral in-memory storage.

---

## 6. Testing Strategy: Unit vs. Real PostgreSQL Integration

FIXO separates fast mock-based unit tests from transactional PostgreSQL integration tests:

### A. Real PostgreSQL Integration Tests (`fixo_test`)
- **Target Suite**: `src/modules/auth/auth-postgres.integration.spec.ts`
- **Database**: Strictly targets `fixo_test` via `TEST_DATABASE_URL`.
- **Verified Behaviors**:
  1. **Readiness Probe & Failure Simulation**: Live PostgreSQL ping reporting `POSTGRESQL_PRISMA`; simulates database failure and verifies `HealthController.getReadiness()` responds with HTTP 503 `SERVICE_UNAVAILABLE`.
  2. **Atomic Single-Use OTP**: Persists challenge, verifies OTP, marks `consumedAt`, creates `User`, rejects replay with HTTP 401.
  3. **Concurrent OTP Verification**: Two simultaneous verifications of the same valid code; exactly 1 succeeds and racing request is rejected with HTTP 401.
  4. **Advisory Lock Concurrency (OTP)**: Uses `pg_advisory_xact_lock(hashtext('fixo_otp_req_lock:' + phone))` to serialize simultaneous OTP requests for the same phone number, granting exactly 1 challenge and rejecting concurrent requests with HTTP 429 (`Resend cooldown active`).
  5. **Distributed Rate Limiting Across Independent Connections**: Two independent `PrismaService` connections sharing PostgreSQL enforce the 45s cooldown and 5-req/15min rate limit across separate instances.
  6. **Refresh Token Rotation**: Atomic claim of previous refresh token and replacement insertion in a single transaction.
  7. **AuthService Refresh Rollback**: Forces replacement persistence to fail inside `authService.refreshTokens`; verifies the transaction rolls back cleanly, the old token remains active (`revokedAt = null`), no replacement persists, and subsequent refresh succeeds.
  8. **Concurrent Refresh with Identical Token**: Two simultaneous refreshes using the same token cannot both succeed; at most 1 succeeds without generating duplicate active tokens.
  9. **Replay Racing with Refresh Rotation (Family Revocation Race)**: Malicious replay racing with legitimate rotation triggers family revocation, terminating all active sessions for the user in PostgreSQL.
  10. **Fail-Closed Unsafe Target Rejection**: Verifies test database safety guards reject non-`fixo_test` targets before destructive cleanup.

```bash
cd backend
npx jest src/modules/auth/auth-postgres.integration.spec.ts
```

### B. Unit, Security & Safety Test Suites
- **Target Suites**:
  - `src/prisma/test-database-safety.util.spec.ts` (12 tests)
  - `src/modules/health/health.controller.spec.ts` (2 tests)
  - `src/modules/services/services.service.spec.ts` (3 tests)
  - `src/modules/auth/auth.service.spec.ts` (17 tests)
  - `src/modules/auth/auth-security.spec.ts` (18 tests)
  - `src/modules/auth/auth-http.spec.ts` (11 tests)
- **Execution**:
```bash
cd backend
npm test
```

---

## 7. Fail-Closed Test Safety Guarantees

To prevent accidental truncation or data loss in development, staging, or production databases, `src/prisma/test-database-safety.util.ts` enforces four mandatory layers of defense:

1. **Dedicated URL Validation**: Target URL must be explicitly provided via `TEST_DATABASE_URL` and must match protocol `postgresql:`.
2. **Local Host Restriction**: Host must strictly resolve to `localhost` or `127.0.0.1` (rejects remote IPs, hostnames, and cloud clusters).
3. **Port Enforcement**: Port must be exactly `5432`.
4. **Database Identity Enforcement**: Pathname must be strictly `/fixo_test`. Any other database (e.g. `fixo_dev`, `production`, `postgres`) is rejected immediately.
5. **Live Runtime Database Query**: Before executing `TRUNCATE`, `SELECT current_database()` is queried directly from PostgreSQL. If the response is not `'fixo_test'`, the operation throws and destructive cleanup is aborted.
