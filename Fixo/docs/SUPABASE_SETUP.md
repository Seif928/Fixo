# FIXO Supabase development database

- Project: fixo-dev
- Organization: ahmedgamal
- Project ref: bvahuhtlrxnbbllkukhd
- Region: eu-central-1 (Frankfurt)
- Plan: Free. Quoted project cost at creation: USD 0/month. No paid add-ons.
- Dashboard: https://supabase.com/dashboard/project/bvahuhtlrxnbbllkukhd

## Run the backend
Requires Node.js 20.6+ (verified with Node 24).
From Fixo/backend:
```powershell
npm run start:supabase
```
Uses the ignored .env.supabase file, port 3001, TLS, and the free IPv4 session pooler on port 5432. The existing .env remains the local Docker profile. Avoid pre-setting DATABASE_URL in your terminal: environment variables override Node's env file.

Readiness: http://localhost:3001/api/v1/health/ready
Swagger: http://localhost:3001/api/docs

## Access model
Flutter calls NestJS. NestJS uses Prisma with the dedicated fixo_backend login. This role has SELECT/INSERT/UPDATE/DELETE only on the 18 FIXO tables, no schema creation, no role creation, and no RLS bypass. Backend authorization remains responsible for individual user access. Per-table RLS policies admit only fixo_backend. anon/authenticated have no table privileges.

Credentials are stored only in .env.supabase, which Git ignores. Do not publish that file or copy database credentials into Flutter. Demo seeding and in-memory fallback are disabled in the cloud profile. Existing development SMS remains sandbox-only: this does not send real SMS.

## Schema history
The existing Prisma migration 20261031202219_init_fixo_schema was applied through Supabase MCP, together with RLS and API-role revocations. A second Supabase migration fixo_backend_access created the backend access role and policies.
Supabase migration history is authoritative for this initial remote provisioning. Prisma's _prisma_migrations table was NOT initialized remotely. Do not run prisma migrate deploy/dev against this database without a deliberate Prisma baseline and a separate migration credential. The runtime login intentionally cannot perform DDL.
Local Prisma source: backend/prisma/schema.prisma.
New tables must receive appropriate grants and RLS policies before runtime use.

## Tests
TEST_DATABASE_URL remains the dedicated local localhost:5432/fixo_test target. Destructive integration tests must never target Supabase.
Cloud smoke verification uses live reads and a transaction that always rolls back.

## Current API coverage
Implemented: OTP request/verify, token refresh/logout, current user, service categories/list/detail, professional listing, health/readiness.
Database tables exist but API implementations are still needed for booking lifecycle, dispatch/job offers, address management, verification documents, payments, chat, and reviews.
Tables being present does not imply these workflows are complete. Real SMS, payment processing, and other external services are not included in the free database setup.
