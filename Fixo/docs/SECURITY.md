# FIXO — Backend Security Architecture & Hardening Guide (`docs/SECURITY.md`)

## 1. Executive Summary
Following an independent static code, transaction isolation, and threat-model re-review, the FIXO backend authentication and marketplace subsystems have undergone final security remediation (**Phase 2.1.1**). All confirmed defects regarding transaction rollbacks, race conditions, telecom simulation, and health checks have been resolved.

---

## 2. Cryptographic Secret Management & Key Rotation

### 2.1 Invariant Rules
- Hardcoded fallback secrets in code have been completely eradicated.
- `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` must be cryptographically independent (distinct keys) with a minimum length of 32 characters (256-bit entropy recommended).
- Startup validation (`validateAuthSecurityConfig`) executes on application boot. If any secret is missing, shorter than 32 characters, matches known example defaults (`fixo-local-dev...`, `replace-with...`, `change-me`, etc.), or if access and refresh secrets are identical, **the application refuses to start with a fatal error**.
- In production, `OTP_HMAC_SECRET` is also required as an independent 32-character key bound to Egyptian mobile number hashing.

### 2.2 Key Rotation Procedure
If an environment previously ran with legacy default secrets, or in case of suspected secret compromise:
1. **Generate New Cryptographic Keys**:
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
2. **Update Environment Secrets**: Set new distinct values for `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, and `OTP_HMAC_SECRET`.
3. **Revoke Active Refresh Tokens**:
   Execute a bulk database revocation against the PostgreSQL database:
   ```sql
   UPDATE "RefreshToken" SET "revokedAt" = NOW() WHERE "revokedAt" IS NULL;
   ```
4. **Deploy Application**: Existing access tokens will expire within 15 minutes (`ACCESS_TOKEN_TTL_SECONDS = 900`). Any attempts to refresh using tokens signed with the old refresh secret will be rejected by HMAC verification, forcing users to authenticate cleanly via SMS OTP.

---

## 3. OTP Issuance, Cooldown & Telecom Gateway Isolation

### 3.1 Atomic OTP Issuance & Cooldown Enforcement
- **Defect Resolved**: OTP cooldown checking, 15-minute sliding window counting, and challenge creation previously had a TOCTOU race window.
- **Remediation**:
  - **In PostgreSQL**: `AuthService.requestOtp` runs within a transaction with `pg_advisory_xact_lock(hashtext('fixo_otp_req_lock:' || phone))`. This strictly serializes concurrent requests for the same phone number across multiple backend instances. The second transaction unblocks, reads the freshly committed challenge, and aborts with HTTP 429 (`Resend cooldown active`).
  - **In In-Memory Store**: A single synchronous turn `atomicRequestOtpChallenge` performs cooldown validation, rate-limit quota check, and challenge insertion, eliminating asynchronous interleaving.
- **Cooldown & Rate Limits**: 45-second server-side resend cooldown; 5 requests max per 15-minute sliding window; 5 failed verification attempts trigger challenge lockout.

### 3.2 Random Generation & Log Redaction
- OTP codes are generated via `crypto.randomInt(100000, 1000000)` (CSPRNG).
- Fixed OTP generation is strictly restricted to automated unit test suites (`NODE_ENV === 'test' && ALLOW_TEST_FIXED_OTP === 'true'`).
- Raw OTP codes are **never** logged in application logs and are **never** returned in API responses (`demoHint` removed).
- Telecom logs strictly mask Egyptian phone numbers (e.g., `+2010*****789`).

### 3.3 Telecom SMS Gateway Invariant & Fail-Closed Behavior
- **Defect Resolved**: Production telecom provider previously reported `delivered: true` without an actual provider gateway.
- **Remediation**:
  - `ProductionTelecomSmsProvider` **fails closed** with HTTP 503 (`SERVICE_UNAVAILABLE`).
  - Validates `SMS_PROVIDER_TYPE` against explicit runtime allowlist: `SUPPORTED_SMS_PROVIDERS = ['DEV_SANDBOX_SMS', 'TWILIO', 'VICTORYLINK', 'VODAFONE_EG']`.
  - In development/sandbox environments, `DevSmsProvider` explicitly reports `delivered: false, simulated: true`.

---

## 4. Refresh Token Rotation & Replay Revocation Persistence

### 4.1 Transaction Rollback Defect & Remediation
- **Defect Resolved**: In commit `9fccb9a`, replay detection revoked tokens inside `prisma.$transaction` and then threw `UnauthorizedException`. Prisma caught the exception and performed `ROLLBACK`, undoing the token revocations in the database!
- **Remediation**:
  - The transaction callback now updates the revoked tokens and returns a structured result `{ status: 'REPLAY_DETECTED', userId }`.
  - The transaction commits cleanly to the database.
  - `AuthService` throws `UnauthorizedException` **outside** the committed transaction.
  - The revocations in PostgreSQL remain permanently persisted on disk.
- **Session Family vs All-Device Revocation**:
  - Token replay indicates token leakage or theft. Family revocation immediately terminates all active refresh tokens for the compromised `userId`.
  - **Access Token TTL Window**: Previously issued access tokens remain valid until their 15-minute TTL expires (`ACCESS_TOKEN_TTL_SECONDS = 900`). Immediate access revocation requires an in-memory or Redis-backed access token blocklist.

---

## 5. Storage Liveness, Readiness & Fallback Policy

### 5.1 Separate Liveness and Readiness Probes
- `GET /api/v1/health`: Liveness probe verifying the Node.js / NestJS process is running.
- `GET /api/v1/health/ready`: Readiness probe executing a real-time live ping (`SELECT 1` with 1000ms timeout).
  - Returns HTTP 200 `{ status: "ready", database: { ready: true, storageMode: "..." } }` if operational.
  - Returns HTTP 503 `{ status: "not_ready", database: { ready: false, reason: "..." } }` if the database is unreachable.
  - Sanitizes all connection strings and credentials from health diagnostics.

### 5.2 Strict Production Fallback Prohibition
- `ALLOW_IN_MEMORY_FALLBACK` is strictly forbidden in production. If PostgreSQL cannot be reached, the application crashes immediately on boot.
- Permitted strictly in local development or test suites via `ALLOW_IN_MEMORY_FALLBACK="true"`.

---

## 6. Public Marketplace Privacy Protection

### 6.1 Professional Discovery Policy
- Only technicians with `verificationStatus === 'APPROVED'` are returned in public searches. Profiles in `DRAFT`, `PENDING_REVIEW`, `ACTION_REQUIRED`, or `SUSPENDED` are strictly excluded.
- The dedicated `PublicProfessionalDto` strips:
  - Private telephone numbers (`user.phone`).
  - Regulatory verification dossier codes (`dossierCode`).
  - Internal administrative review notes (`reviewerNote`).
- Verification badges are never fabricated if not present in the database.
- In production, when the database is empty, genuine empty lists (`[]`) are returned; synthetic demo records are strictly blocked from leaking into production responses.

---

## 7. Status Summary: Implemented vs Pending Real Infrastructure

| Feature / Control | Implementation Status | Test Status | Infrastructure Dependency |
|---|---|---|---|
| **Cryptographic Secrets Validation** | Implemented | Verified (Unit + HTTP) | None |
| **Server-Side Resend Cooldown (45s)** | Implemented | Verified (Atomic Concurrency) | None |
| **Distributed Rate Limiting (5 / 15m)** | Implemented | Verified (Atomic Concurrency) | None |
| **Atomic Single OTP Consumption** | Implemented | Verified (Concurrent Collision) | PostgreSQL Advisory Lock / In-Memory |
| **Replay Revocation Persistence** | Implemented | Verified (Persisted State Inspected) | PostgreSQL / In-Memory |
| **Telecom Fail-Closed SMS** | Implemented | Verified (HTTP 503 Fail-Closed) | Production Telecom Credentials (Pending) |
| **Storage Readiness Probe (/ready)** | Implemented | Verified (200 OK & 503 Mocked) | PostgreSQL Port 5432 (Pending Local Daemon) |
| **Marketplace PII & Status Filter** | Implemented | Verified (Negative Fixtures Excluded) | None |
