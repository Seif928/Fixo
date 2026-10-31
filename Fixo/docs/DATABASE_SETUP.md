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
ALLOW_IN_MEMORY_FALLBACK="false" # Strictly enforce real PostgreSQL connectivity
```

When `ALLOW_IN_MEMORY_FALLBACK="false"`:
- The backend verifies live PostgreSQL connectivity on boot via `PrismaService.checkReadiness()`.
- If PostgreSQL is unreachable or credentials fail, the server terminates immediately rather than silently falling back to ephemeral in-memory storage.

---

## 6. Testing Strategy: Unit vs. Real PostgreSQL Integration

FIXO separates fast mock-based unit tests from transactional PostgreSQL integration tests:

### A. Real PostgreSQL Integration Tests
- **Target Suite**: `src/modules/auth/auth-postgres.integration.spec.ts`
- **Database**: Strictly targets `fixo_test`.
- **Verified Behaviors**:
  1. **Readiness Probe**: Live PostgreSQL ping reporting `POSTGRESQL_PRISMA` storage mode.
  2. **Atomic Single-Use OTP**: Persists challenge, verifies OTP, marks `consumedAt`, creates `User`, rejects replay with HTTP 401.
  3. **Advisory Lock Concurrency**: Uses `pg_advisory_xact_lock(hashtext(phone))` to serialize simultaneous OTP requests for the same phone number, granting exactly 1 challenge and rejecting concurrent requests with HTTP 429 (`Resend cooldown active`).
  4. **Refresh Token Rotation**: Atomic claim of previous refresh token and replacement insertion in a single transaction.
  5. **Replay Revocation Persistence**: Family revocation commits to PostgreSQL upon replay attack detection before returning HTTP 401.
  6. **Transaction Rollback**: Clean database rollback on unhandled transaction errors.

```bash
cd backend
npx jest src/modules/auth/auth-postgres.integration.spec.ts
```

### B. Unit & Security Tests (Mocked)
- **Target Suites**:
  - `src/modules/health/health.controller.spec.ts`
  - `src/modules/auth/auth.service.spec.ts`
  - `src/modules/auth/auth-security.spec.ts`
  - `src/modules/auth/auth-http.spec.ts`
  - `src/modules/services/services.controller.spec.ts`
- **Execution**:
```bash
cd backend
npm test
```
