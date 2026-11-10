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

The hosted Account Portal trial succeeded after correcting phone requirements. The user completed Google sign-in; the visible default-redirect page confirmed a signed-in account but explicitly said Clerk was not connected to the application. Agent then verified sign-out and left the sign-in page available. Do not report Clerk as connected to FIXO production. Existing FIXO login and data remain unchanged.

The trial initially required a phone and rejected Egyptian numbers. With explicit action-time user approval, Sign-up with phone and Sign-in with phone were disabled and saved. The continuation form then contained only Username; the phone error/field disappeared. Email verification, Google/Apple, password protections and MFA settings were not changed. Any remaining paid MFA settings still require a separate free-production review; no upgrade or billing was enabled.

Official @clerk/backend 3.27.0 is now pinned in backend/package.json/lockfile. ClerkTrialVerifier and twelve real-RSA regression cases were added. The adapter verifies signatures, issuer, authorized parties, token expiry and session claims; it ignores email/role claims and issues no FIXO tokens. It is deliberately NOT registered in AuthModule, existing guards or any HTTP route. No provider credential or user import/link was configured.

Verification: 511 backend tests in 56 suites passed with isolated local fixo_test; lint and Nest build passed. The compiled adapter loads under Node 24 with --no-experimental-require-module. Public JWKS for the observed Fixo development issuer was reachable and contained one RSA signing key. No secret key, live user token or identity was used in the RSA tests. These results do not establish end-to-end Clerk-to-FIXO authentication, password recovery, revocation or Flutter Web integration.

## Implementation gates after the trial

1. Verify the user-reported/visible sign-in, sign-out, verification and recovery behavior. Do not handle passwords/OTPs in chat, extract browser tokens or weaken bot/security protections.
2. Validate SDK support separately for Flutter native and Web. The current community clerk_flutter beta page lists Android/iOS/macOS; it must not be assumed to cover the existing Flutter Web target. Keep Flutter/Dart UI and do not scaffold a replacement Next.js application from the Dashboard's default prompt.
3. Build a staged backend identity exchange using the official Clerk verifier, exact trusted issuer, signature/expiry/authorized-party checks and validated session status. Keep FIXO IDs and existing role checks authoritative; token decoding or matching an email alone must not link an existing account. Prove linkage with both identities or a separately approved migration.
4. Define account/session refresh, revocation, deleted-account handling, current phone alias/password behavior and rollback before enabling any Clerk-issued FIXO session. New provider JWTs must not be accepted by existing guards accidentally.
5. Stay on free features; no SMS, paid MFA, passkey/enterprise add-on, production-domain purchase or plan upgrade. Leave pre-existing security settings unchanged without the required explicit approval.

Sources checked 2026-11-11: https://clerk.com/pricing ; https://clerk.com/docs ; https://pub.dev/packages/clerk_flutter ; https://clerk.com/docs/reference/backend/verify-token ; https://clerk.com/docs/guides/development/migrating/overview . Current server remains NestJS; Dart rewrite remains stopped.
