# FIXO remaining verification and delivery — 2026-11-10

This checkpoint supersedes the completion/pending counts in the November 2–3 status documents. Implemented endpoints are not proof of complete production journeys.

## Latest evidence

- Source: API account/avatar correction 95d6563; Web/chat release b68aacf; branch codex/fixo-premium-repair. Booking evidence remains recorded in 6c42177/0fc54f3.
- Backend: latest full verification 499 tests / 55 suites, TypeScript check and build passed. Flutter: last verified Web/Android release has 545 passed, two deliberately opt-in skips and clean analyze; no Flutter source changed in the API-only follow-up.
- TestSprite frontend: fresh seven-case batch passed. Backend four-case rerun remains unconfirmed; CLI credential-file EPERM persists and the user's terminal result has not arrived.
- Real local PostgreSQL booking widget integration passed: full calendar, exact 21:45 time, real pricing, cash confirmation, PENDING_DISPATCH, one pending cash payment, paidAt null, duplicate-safe reopen. This is not a native/browser authenticated booking test. See LOCAL_BOOKING_VERIFICATION.md.
- Android public-navigation emulator smoke passed. Ordinary APK and Web builds passed. Both Web hosting origins matched the verified artifact.
- Fixed booking confirmation/footer overlap and redundant success snackbar covering checkout actions.

## Priority 1 — remaining runtime verification

1. Authenticated current-production photo upload/replacement, Google first-profile completion, support conversation, customer/professional/admin authorization journeys. Use authorized test identities and private fixtures, never real identity documents or automatic professional approval.
2. Actual push receipt on Android and browser: permission grant/deny, foreground/background, token rotation and logout. Server authorization/configuration checks do not prove delivery. Earlier Android registration failure still needs reproduction and diagnosis.
3. Native complete booking, camera/gallery recovery, GPS denial/manual fallback and lifecycle checks. Current Android smoke covers public navigation only.
4. iOS build/runtime, Apple identity, APNs, permissions and signing remain unverified; require an appropriate Apple environment/account. No paid membership has been purchased.
5. Fresh TestSprite backend run: awaiting user-terminal result. Do not reuse old passes as a new run or bypass credential permissions.

## Priority 2 — implementation and audit

- Chat photo attachment is now implemented and locally verified: camera/library selection, explicit preview confirmation, private normalized WebP storage, authenticated participant-only reads, upload limit 2 MB, transaction-failure cleanup and Android scoped interrupted-photo recovery. Cloud authenticated/device delivery still needs verification. See CHAT_MEDIA_DELIVERY_2026-11-10.md.
- Complete a focused media/lifecycle/security review and current dependency advisory assessment. Passing regression suites do not establish a comprehensive clean security audit.
- Favorites, complaints, professional schedules/leaves and account deletion have backend controllers now. The older status file incorrectly lists these wholesale as missing. Verify the corresponding UI, authorization, retention and end-to-end behavior before closing them.
- Reconcile custom catalog creation/deactivation and original/Gemini branch integration against current source; older pending lists are not reliable evidence of absence.
- Continue responsive visual QA in Arabic/English, light/dark and narrow/wide screens; “premium” is not a test result.

## External activation

- Cash checkout is verified; electronic gateway adapter is not implemented/activated. Merchant provider/account selection, server adapter, signed/idempotent webhooks and rejection/refund tests remain required. See PAYMENT_APPLE_ACTIVATION.md.
- Apple Pay and Apple login are not live. Never display an unavailable method as operational or mark payment successful from a redirect.
- Friend's admin email remains deferred. Do not invent an invitation or a second administrator.
- Retain free-plan limits; do not activate billing, SMS or paid map services. Provider transaction fees/Apple membership cannot be promised free.

Do not modify production bookings/payments or activate unpriced catalog drafts to manufacture test coverage.

## Follow-up verification in this session

- Flutter now passes 545 tests with the same two deliberate opt-in skips; both changed chat golden references were visually inspected in English/light and Arabic/dark.
- Backend now passes all 493 tests in 55 suites, including real local PostgreSQL photo persistence/ownership and HTTP multipart/authorization tests. Private object storage was substituted in the integration test; this does not prove cloud media delivery.
- Fixed a reproduced push opt-in/logout race: Firebase initialization completing after logout can no longer trigger a stale OS permission prompt or proceed to registration.
- No merchant or Apple activation, billing change, production booking or real professional approval was performed.

Account follow-up: [administrator self-deletion and delayed avatar corrections](ACCOUNT_PRIVACY_REVIEW_2026-11-10.md). Broader deletion concurrency/retention and external device checks remain open; do not infer complete coverage from these fixes.
