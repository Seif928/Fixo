# Clerk trial — not a production authentication migration

User explicitly chose to test Clerk first while retaining the working FIXO authentication and all existing accounts/bookings. Do not infer approval for bulk user export/import, automatic email-based linking, role assignment or disabling Firebase.

## Observed existing account configuration

- Organization A&A's Organization, Hobby. Existing Fixo application app_3Lvpiq2T6vmqr51lkOmQFz7Tpuj, development instance ins_3LvpirfiPLys7H3w8U6djHfbL6X. No production environment.
- Frontend API: https://stable-panda-3651.clerk.accounts.dev . Account Portal sign-in: https://stable-panda-3651.accounts.dev/sign-in . URLs/IDs here are public configuration, not credentials.
- Email sign-up/sign-in and sign-up verification enabled; email code enabled, email link disabled. Password sign-up/add-password enabled, minimum 15 characters, compromised-password rejection enabled, Device Trust enabled.
- Google and Apple social sign-in already enabled using shared DEVELOPMENT credentials. This is not proof that the user's production Apple/Google integrations are configured.
- Dashboard identifies two paid-development features: SMS code MFA and Phone numbers. Development trial availability is not evidence of free production availability. No paid feature, billing change or security toggle was changed.
- No Clerk plugin found in the connector search. Dashboard access was used read-only; no secret key was revealed, copied or stored.

## Current trial state

The existing hosted Account Portal was opened separately. User said they will test Google login and send the outcome. Actual end-user login/logout is still pending; do not report Clerk as connected to FIXO production. The existing FIXO login, backend and data remain unchanged. No Clerk SDK or replacement auth route has been installed yet.

## Implementation gates after the trial

1. Verify the user-reported/visible sign-in, sign-out, verification and recovery behavior. Do not handle passwords/OTPs in chat, extract browser tokens or weaken bot/security protections.
2. Validate SDK support separately for Flutter native and Web. The current community clerk_flutter beta page lists Android/iOS/macOS; it must not be assumed to cover the existing Flutter Web target. Keep Flutter/Dart UI and do not scaffold a replacement Next.js application from the Dashboard's default prompt.
3. Build a staged backend identity exchange using the official Clerk verifier, exact trusted issuer, signature/expiry/authorized-party checks and validated session status. Keep FIXO IDs and existing role checks authoritative; token decoding or matching an email alone must not link an existing account. Prove linkage with both identities or a separately approved migration.
4. Define account/session refresh, revocation, deleted-account handling, current phone alias/password behavior and rollback before enabling any Clerk-issued FIXO session. New provider JWTs must not be accepted by existing guards accidentally.
5. Stay on free features; no SMS, paid MFA, passkey/enterprise add-on, production-domain purchase or plan upgrade. Leave pre-existing security settings unchanged without the required explicit approval.

Sources checked 2026-11-11: https://clerk.com/pricing ; https://clerk.com/docs ; https://pub.dev/packages/clerk_flutter ; https://clerk.com/docs/reference/backend/verify-token ; https://clerk.com/docs/guides/development/migrating/overview . SDK candidate observed from npm registry: @clerk/backend 3.27.0, not installed.
