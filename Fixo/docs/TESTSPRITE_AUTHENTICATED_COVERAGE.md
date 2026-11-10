# FIXO TestSprite authenticated coverage

Target web: https://fixo-web-blue.vercel.app
Target API: https://fixo-api.vercel.app/api/v1
Existing frontend project: 235a25d4-137f-4ec5-a31b-90cb6dba7026
Existing backend project: ece03c86-c961-419b-9694-76b40bc5aaa4

Status (2026-11-10): browser control restored. The original BKG-003 run stopped at sign-in. Flutter web semantics were enabled and verified locally and on the production Vercel domain. Deployment dpl_9GYCqdsBYxgnaNn3K4fCfnibcSPK is READY. BKG-003 has been revised to explicitly use the configured customer account and inspect the profile; its new cloud run PASSED on 2026-11-10. BKG-006 (259775cb-e21b-4d51-9f4e-b08058dda334) was added for logout cancellation, confirmed logout and protected-profile redirection; the cloud run PASSED (14 actions), including cancellation, confirmed sign-out and rejection of protected-profile access afterward. The accessibility build is also deployed to Firebase Hosting. Admin, technician and native-device coverage is not yet verified. No API key or password is stored here.

## Required authenticated environments
- Guest: no credentials; public onboarding and negative access checks.
- Customer: dedicated verified FIXO test account with completed profile, phone/password supplied only through TestSprite's secure account-login settings.
- Technician: separate test account with an approved synthetic professional dossier. Do not fabricate an approved identity in production or bypass onboarding.
- Administrator: use TestSprite's manual/SSO sign-in browser with an explicitly authorized admin account; validate access inside that captured FIXO session. A session in the user's ordinary browser is not a captured TestSprite session. Never turn off JWT/admin guards or grant public admin access.
- Capture admin and customer sessions separately. Run logout last for each identity, then renew the captured session before further authenticated cases. Do not put credentials in plans, source code, screenshots or reports.

## Bounded first batch (read/navigation only)
1. Guest opens /#/auth/phone; invalid phone format and empty password show localized field validation without successful login.
2. Guest opening /#/admin, /#/customer/profile and /#/support must be redirected to login; unauthenticated support API and admin support API return 401.
3. Customer signs in and opens /#/customer/home then /#/customer/profile. Saved name/avatar are visible. Sign-out entry remains in profile.
4. Customer opens a real service's Book action, /#/customer/bookings/new with its required offering context. Open full calendar, select a date beyond four days, choose 21:45; confirm selected date/time in the draft UI without submitting a live booking.
5. Customer opens /#/support, reads own test conversation, returns to the list. A different account must not see it.
6. Technician opens /#/pro/dashboard and its Customer support entry. Confirm the current professional role and actual job details, including exact appointment time when fixture data exists.
7. Administrator opens /#/admin and /#/admin/support. Read test conversations and service drafts; opening a view must not publish services or alter payments.
8. Customer and administrator logout tests execute last: /#/auth/logout, cancel leaves the session intact; confirm returns to signed-out state; protected pages become inaccessible.
9. Repeat key screens in Arabic RTL/light/dark at mobile width and desktop width; flag clipping, unreachable buttons and misleading security/payment text.

## Staging-only write batch after the first batch
- Create/send/reply/close a support conversation using synthetic fixtures; verify ownership, admin authorization and failed-send draft preservation.
- Create a booking on isolated test data, reopen checkout and verify the same Cairo date/time persists. Cash payment remains PENDING and unpaid. Verify retry behavior and reject invalid/past times.
- Test profile edits/avatar uploads and technician onboarding using synthetic documents only.
- Do not charge real cards, modify real admin memberships, publish live catalog prices, approve real identity documents or delete production records.

## Reporting and credits
Read current plan/balance before runs; use only available free credits, no upgrades or auto-topups. Begin with a small selected batch rather than generating/executing every case. Login-required cases with no valid captured session are BLOCKED, not passed. A successful redirect proves route protection only; it does not prove authenticated booking or admin functionality. Report native Android/iOS as untested unless device tests actually run; Flutter Web/API coverage is not native-device coverage.



## Additional verification (2026-11-10)
- Targeted Flutter login/logout/home tests: 10 passed.
- dart analyze lib/main.dart: no issues.
- Guest admin navigation redirects to the sign-in form.
- Anonymous support/threads and support/admin/threads requests both return HTTP 401.
- The three previously failed cases were re-run: TC-001 passed after web semantics; BKG-004 and BKG-005 passed after pricing/cash chips gained accessible explanatory dialogs. Their original test plans were preserved. Dashboard now shows 7 passed, 0 failed, 0 blocked. Two onboarding/location cases retain earlier successful runs; this was not a fresh simultaneous run of all seven.


## Onboarding repair deployment
- Source commit: 1a60dfd; production Vercel deployment dpl_Dfm9qndd5smFzWNqbfKoXSJ3up5Z, also synced to Firebase Hosting.
- Public pricing and cash explanation buttons verified on the production domain; dialogs explain fees/payment without fabricating a price or payment success.
- Regression test observed failing before implementation, then all 10 widget_test.dart tests passed; full flutter analyze found no issues and release web build succeeded.
- Remaining scope: authenticated administrator and technician sessions, complete booking/support workflows, and native Android/iOS device testing are not covered by these seven cases.

