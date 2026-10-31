# FIXO — Backend Security Architecture & Hardening Guide (`docs/SECURITY.md`)

## 1. Executive Summary
Following an independent static code and threat model audit, the FIXO backend authentication and marketplace subsystems have been hardened to eliminate critical security vulnerabilities, predictability flaws, race conditions, and accidental production information leaks.

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

## 3. OTP Verification & Telecom Gateway Isolation

### 3.1 Random Generation Invariant
- OTP codes are generated via `crypto.randomInt(100000, 1000000)` (cryptographically secure random integer).
- Fixed OTP generation is strictly restricted to isolated automated test runs (`NODE_ENV === 'test' && ALLOW_TEST_FIXED_OTP === 'true'`). It is forbidden in development, staging, and production.
- Raw OTP codes are **never** logged in application logs and are **never** returned in API responses (`demoHint` removed).
- Telecom logs strictly mask Egyptian phone numbers (e.g., `+2010*****678`).

### 3.2 Telecom SMS Gateway Invariant
- In production (`NODE_ENV === 'production'`), `SMS_PROVIDER_TYPE` must be configured with a real telecom SMS provider (`TWILIO`, `VICTORYLINK`, or `VODAFONE_EG`).
- If `SMS_PROVIDER_TYPE` is unset or set to `DEV_SANDBOX_SMS` in production, application bootstrap halts immediately with a fatal error.
- In development/sandbox environments, `DevSmsProvider` explicitly reports `delivered: false, simulated: true`.

### 3.3 Server-Side Resend Cooldown & Distributed Rate Limiting
- **45-second Resend Cooldown**: Server tracks the timestamp of the last challenge created for each Egyptian mobile number. If a new request arrives within 45 seconds, it is rejected with HTTP 429 (`TOO_MANY_REQUESTS`).
- **15-minute Sliding Window Rate Limit**: Maximum 5 OTP requests per phone number within any 15-minute window.
- **Brute-Force Lockout**: 5 failed verification attempts permanently lock the challenge with HTTP 429.

---

## 4. Concurrency Safety & Refresh Token Rotation

### 4.1 Atomic OTP Consumption
- OTP challenges can be consumed **only once**.
- When PostgreSQL is connected, consumption uses atomic conditional updates:
  ```sql
  UPDATE "OtpChallenge"
  SET "consumedAt" = NOW()
  WHERE "id" = $1 AND "phone" = $2 AND "consumedAt" IS NULL
    AND "attempts" < 5 AND "expiresAt" > NOW();
  ```
- If concurrent requests attempt to verify the same code, only one transaction matches `consumedAt IS NULL`; all concurrent attempts receive HTTP 401.

### 4.2 Refresh Token Rotation & Replay Attack Family Revocation
- Every refresh token exchange revokes the old refresh token and issues a new refresh token inside a single database transaction.
- **Replay Attack Detection**: If an already-revoked refresh token is presented, the system detects a token theft/replay attack, immediately executes **family revocation** (terminating all active sessions for that `userId`), and logs a high-severity security alert.

---

## 5. PostgreSQL Persistence & Fallback Policy

### 5.1 Strict Separation of Environments
- **Production Invariant**: `ALLOW_IN_MEMORY_FALLBACK` is strictly forbidden in production. If PostgreSQL cannot be reached, the application crashes immediately on boot.
- **Development/Test Fallback**: Permitted only when `ALLOW_IN_MEMORY_FALLBACK="true"` is explicitly set in `.env` during local offline development.
- Application health endpoint (`GET /api/v1/health`) reports actual persistence mode (`POSTGRESQL_PRISMA` vs `IN_MEMORY_FALLBACK`) without exposing credentials.

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

