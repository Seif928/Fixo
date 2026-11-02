# FIXO connected services implementation plan

Goal: connect real customer workflows without paid services, fabricated delivery, or client-side database credentials.

Cost constraint reaffirmed by the user on 2026-11-02: no payment card, billing activation, paid plan, or expiring trial. Do not enable a service merely because it has free credits. Google Maps uses public HTTPS Maps URLs for the saved address and directions, without an API key or embedded map. Embedded google_maps_flutter remains inactive because its SDK setup requires billing. No background location access is requested for external maps links.

Architecture: retain Flutter → authenticated NestJS → Prisma/Supabase. Build on existing ChatMessage and BookingStatusEvent records. Keep fixed OTP restricted to local development. Use one agent; no Teamwork.

The user delegated implementation choices and requested execution without further design interviews. Work is split into independently verified subsystems.

## Delivery sequence

- [x] Booking communications API: participant-only message history, send and read acknowledgement; strict validation, bounded pagination and no fabricated professional. Existing ChatMessage schema only.
- [x] In-app notification feed: real booking status events and unread incoming messages, scoped to the authenticated user. Explicitly distinguish this from background push.
- [x] Flutter chat/profile integration: inspected official live Stitch Screens 07/10; authenticated repositories and polling while visible, dispose on exit. Additional profile and active-chat UI coverage remains.
- [ ] Email sign-in: verified email delivery, retain existing session revocation and ownership. Never silently link accounts by an unverified phone/email. Provider configuration is required before claiming delivery works.
- [ ] Android/Web push: Firebase project, platform registrations and device tokens, explicit contextual permission prompt, denied-permission fallback. iOS needs APNs credentials and Apple runtime verification.
- [ ] Vercel: build and verify API/database environment and Flutter Web API URL; no production deployment with sandbox OTP. Credentials stay server-side and ignored by Git.
- [x] Google Maps: inspected live Screen 04 HTML/screenshot, replaced illustrative street grid with user-triggered address search/directions links. Tests cover Arabic address encoding, no default coordinates, launch failure and RTL/dark large-text layout. Embedded maps and GPS selection are not active.

## First subsystem files and tests

Create backend/src/modules/communications/{communications.module,communications.controller,communications.service,communications.service.spec}.ts and dto/communication.dto.ts. Register in AppModule.

Tests first: strangers cannot read/write, assigned pro/customer can participate, no pro means sending unavailable, terminal bookings read-only, messages trim and limit, cursors cannot cross bookings, only incoming messages marked read, feed contains only the user's events/messages. Run focused tests red then green, backend lint/build and the existing suite against local fixo_test. Add real local PostgreSQL integration verification before claiming persistence/authorization complete.

## External prerequisites discovered

- Supabase built-in email is restricted to organization members. Firebase Auth Spark Email/Password is enabled instead; the backend exchanges verified Firebase identities for FIXO sessions. End-user email/Google sign-in runtime verification remains pending.
- Existing production SMS adapter always returns unavailable; no delivery integration exists.
- Firebase Spark project fixo-home-services-6507 and Android/iOS/Web registrations exist. Google provider and Android debug SHA fingerprints are configured. APNs, Web push and server FCM credentials remain unconfigured. Do not invent them or expose sandbox OTP publicly.
- Vercel projects fixo-api/fixo-web are linked; production environment is empty and no deployment exists.

## Verification and delivery

Use deterministic tests by default. Cloud reads only until integration is reviewed; destructive tests only local fixo_test. Commit reviewed task changes and push the current branch, preserving unrelated changes. Report completed subsystems separately from blocked external activation.
