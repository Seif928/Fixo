# FIXO — PostgreSQL Database Setup Guide (`docs/DATABASE_SETUP.md`)

## 1. Prerequisites
- Docker & Docker Compose OR a local PostgreSQL 16+ daemon.
- Node.js 20+ and npm.

---

## 2. Docker Compose Quickstart
To launch a local PostgreSQL container for FIXO development:

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
```bash
# Windows PowerShell
Test-NetConnection -ComputerName localhost -Port 5432
```

---

## 3. Prisma Migrations & Seeding
Once the PostgreSQL container is listening on port 5432:

```bash
cd backend

# Validate schema
npx prisma validate

# Run migrations
npx prisma migrate dev --name init_fixo_schema

# Seed Egyptian marketplace demo data
npm run prisma:seed
```

---

## 4. Environment Configuration
Update `backend/.env`:
```env
DATABASE_URL="postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_dev?schema=public"
ALLOW_IN_MEMORY_FALLBACK="false" # Require real PostgreSQL connection
```

When `ALLOW_IN_MEMORY_FALLBACK="false"`, the backend will verify live PostgreSQL connectivity on boot and fail immediately if port 5432 is unreachable.

